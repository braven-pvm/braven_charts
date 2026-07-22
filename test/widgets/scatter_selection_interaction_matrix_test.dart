import 'dart:math' as math;

import 'package:braven_charts/src/artifacts/chart_view_state.dart';
import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/models/braven_chart_controller.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/scatter_render_config.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scatter selection interaction matrix', () {
    testWidgets('mouse, touch, and keyboard activate the same point identity', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await _pumpScatter(
        tester,
        controller: controller,
        selection: const ChartSelectionConfig(),
      );

      const atlas = ChartPointRef(seriesId: 'accounts', pointIndex: 0);
      final atlasPosition = _pointPosition(tester, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(atlasPosition);
      await mouse.down(atlasPosition);
      await mouse.up();
      await tester.pump();
      expect(controller.selectedPointRefs, {atlas});

      controller.clearPointSelection();
      await tester.pump();
      final touch = await tester.startGesture(
        atlasPosition,
        kind: PointerDeviceKind.touch,
      );
      await touch.up();
      await tester.pump();
      expect(controller.selectedPointRefs, {atlas});

      controller.clearPointSelection();
      controller.clearPointFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.focusedPointRefs, {atlas});
      expect(controller.selectedPointRefs, {atlas});
    });

    for (final mode in const [
      ChartSelectionAcquisitionMode.rectangle,
      ChartSelectionAcquisitionMode.lasso,
    ]) {
      testWidgets('touch ${mode.name} selects the enclosed marker set', (
        tester,
      ) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await _pumpScatter(
          tester,
          controller: controller,
          selection: ChartSelectionConfig(
            acquisitionMode: mode,
            useModifierKeys: false,
          ),
        );

        final atlas = _pointPosition(tester, 0);
        final beacon = _pointPosition(tester, 1);
        final left = math.min(atlas.dx, beacon.dx) - 18;
        final right = math.max(atlas.dx, beacon.dx) + 18;
        final top = math.min(atlas.dy, beacon.dy) - 18;
        final bottom = math.max(atlas.dy, beacon.dy) + 18;
        final path = <Offset>[
          Offset(left, top),
          Offset(right, top),
          Offset(right, bottom),
          Offset(left, bottom),
          Offset(left, top),
        ];
        final touch = await tester.startGesture(
          path.first,
          kind: PointerDeviceKind.touch,
        );
        if (mode == ChartSelectionAcquisitionMode.rectangle) {
          await touch.moveTo(path[2]);
          await tester.pump();
        } else {
          for (final position in path.skip(1)) {
            await touch.moveTo(position);
            await tester.pump();
          }
        }
        await touch.up();
        await tester.pump();

        expect(controller.selectedPointRefs, {
          const ChartPointRef(seriesId: 'accounts', pointIndex: 0),
          const ChartPointRef(seriesId: 'accounts', pointIndex: 1),
        });
        expect(controller.selectionResult.statistics.pointCount, 2);
      });
    }

    testWidgets(
      'shift-wheel zoom and middle-drag pan preserve durable selection',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await _pumpScatter(
          tester,
          controller: controller,
          selection: const ChartSelectionConfig(
            acquisitionMode: ChartSelectionAcquisitionMode.lasso,
          ),
        );

        const beacon = ChartPointRef(seriesId: 'accounts', pointIndex: 1);
        final revision = controller.effectiveDocumentRevision.value!;
        controller.selectPoint(beacon, revision: revision);
        controller.focusPoint(beacon, revision: revision);
        await tester.pump();

        final renderFinder = _chartRenderFinder();
        var renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        var element = renderBox.debugElements.whereType<SeriesElement>().single;
        final originalRange =
            element.transform.dataXMax - element.transform.dataXMin;
        final center = tester.getCenter(renderFinder);
        renderBox.coordinator.addModifierKey(LogicalKeyboardKey.shift);
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, -120),
          ),
        );
        await tester.pump();
        renderBox.coordinator.removeModifierKey(LogicalKeyboardKey.shift);

        renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        element = renderBox.debugElements.whereType<SeriesElement>().single;
        final zoomedRange =
            element.transform.dataXMax - element.transform.dataXMin;
        expect(zoomedRange, lessThan(originalRange));
        expect(controller.selectedPointRefs, {beacon});
        expect(controller.focusedPointRefs, {beacon});

        final beforePan = element.transform.dataXMin;
        final middle = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kMiddleMouseButton,
        );
        addTearDown(middle.removePointer);
        await middle.addPointer(location: Offset.zero);
        await middle.moveTo(center);
        await middle.down(center);
        await middle.moveTo(center + const Offset(56, 0));
        await tester.pump();
        await middle.up();
        await tester.pump();

        renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
        element = renderBox.debugElements.whereType<SeriesElement>().single;
        expect(element.transform.dataXMin, isNot(closeTo(beforePan, 0.0001)));
        expect(controller.selectedPointRefs, {beacon});
        expect(controller.focusedPointRefs, {beacon});
        expect(controller.selectionResult.points.single.point.label, 'Beacon');
        await tester.pump(const Duration(milliseconds: 201));
      },
    );

    testWidgets(
      'data updates refresh selected statistics and prune removed references',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        var points = _points;
        final publishedSelectionYs = <double?>[];
        late StateSetter rebuild;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return SizedBox(
                    width: 520,
                    height: 360,
                    child: BravenChartPlus(
                      bravenChartController: controller,
                      showLegend: false,
                      series: [
                        ScatterChartSeries(
                          id: 'accounts',
                          points: points,
                          markerRadius: 7,
                        ),
                      ],
                      interactionConfig: InteractionConfig(
                        onSelectionResultChanged: (result) {
                          publishedSelectionYs.add(
                            result.isEmpty
                                ? null
                                : result.points.single.point.y,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const beacon = ChartPointRef(seriesId: 'accounts', pointIndex: 1);
        final revision = controller.effectiveDocumentRevision.value!;
        controller.selectPoint(beacon, revision: revision);
        controller.focusPoint(beacon, revision: revision);
        await tester.pump();
        expect(controller.selectionResult.points.single.point.y, 5);
        expect(publishedSelectionYs, [5]);

        rebuild(() {
          points = const [
            ChartDataPoint(x: 2, y: 3, label: 'Atlas'),
            ChartDataPoint(x: 4, y: 9, label: 'Beacon'),
            ChartDataPoint(x: 8, y: 8, label: 'Comet'),
          ];
        });
        await tester.pump();
        await tester.pump();

        expect(controller.selectedPointRefs, {beacon});
        expect(controller.focusedPointRefs, {beacon});
        expect(controller.selectionResult.points.single.point.y, 9);
        expect(controller.selectionResult.statistics.y?.mean, 9);
        expect(publishedSelectionYs, [5, 9]);

        rebuild(() {
          points = const [ChartDataPoint(x: 2, y: 3, label: 'Atlas')];
        });
        await tester.pump();
        await tester.pump();

        expect(controller.selectedPointRefs, isEmpty);
        expect(controller.focusedPointRefs, isEmpty);
        expect(controller.selectionResult.isEmpty, isTrue);
        expect(publishedSelectionYs, [5, 9, null]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('activating a cluster drills into its raw source extent', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                series: const [
                  ScatterChartSeries(
                    id: 'clusters',
                    points: [
                      ChartDataPoint(x: 1, y: 1),
                      ChartDataPoint(x: 1.1, y: 1.1),
                      ChartDataPoint(x: 9, y: 9),
                    ],
                    renderMode: ScatterRenderMode.clusters,
                    clusterConfig: ScatterClusterConfig(
                      cellSize: 72,
                      showZones: true,
                      drillOnTap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = _chartRenderFinder();
      var renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      final beforeXSpan =
          renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;
      final beforeYSpan =
          renderBox.transform!.dataYMax - renderBox.transform!.dataYMin;
      final clusterPosition = _pointPosition(tester, 0);
      const overviewActionKey = ValueKey<String>(
        'scatter-cluster-back-to-overview',
      );
      expect(find.byKey(overviewActionKey), findsNothing);

      await tester.tapAt(clusterPosition);
      await tester.pump();

      renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      expect(
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin,
        lessThan(beforeXSpan),
      );
      expect(
        renderBox.transform!.dataYMax - renderBox.transform!.dataYMin,
        lessThan(beforeYSpan),
      );
      expect(controller.selectedPointRefs, isEmpty);

      final overviewAction = find.byKey(overviewActionKey);
      expect(overviewAction, findsOneWidget);
      expect(tester.getSize(overviewAction).height, greaterThanOrEqualTo(48));

      await tester.tap(overviewAction);
      await tester.pump();

      renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
      expect(
        renderBox.transform!.dataXMax - renderBox.transform!.dataXMin,
        closeTo(beforeXSpan, 0.0001),
      );
      expect(
        renderBox.transform!.dataYMax - renderBox.transform!.dataYMin,
        closeTo(beforeYSpan, 0.0001),
      );
      expect(overviewAction, findsNothing);
    });
  });
}

const _points = [
  ChartDataPoint(x: 2, y: 3, label: 'Atlas'),
  ChartDataPoint(x: 4, y: 5, label: 'Beacon'),
  ChartDataPoint(x: 8, y: 8, label: 'Comet'),
];

Future<void> _pumpScatter(
  WidgetTester tester, {
  required BravenChartController controller,
  required ChartSelectionConfig selection,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 520,
          height: 360,
          child: BravenChartPlus(
            bravenChartController: controller,
            showLegend: false,
            series: const [
              ScatterChartSeries(
                id: 'accounts',
                points: _points,
                markerRadius: 7,
              ),
            ],
            interactionConfig: InteractionConfig(selection: selection),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Offset _pointPosition(WidgetTester tester, int pointIndex) {
  final renderFinder = _chartRenderFinder();
  final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
  final element = renderBox.debugElements.whereType<SeriesElement>().single;
  final hit = element.dataHitForPointIndex(pointIndex)!;
  return tester.getTopLeft(renderFinder) +
      renderBox.plotToWidget(hit.plotPosition);
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
