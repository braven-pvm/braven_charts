import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and hit-tests two independent Donut rings', (
    tester,
  ) async {
    final tappedSeries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 400,
              child: BravenChartPlus(
                key: const ValueKey('concentric-donut'),
                showLegend: false,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.25,
                  ringGap: 4,
                ),
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                onPointTap: (_, seriesId) => tappedSeries.add(seriesId),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'outer',
                    values: const {'Current': 100},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                    donutStyle: const DonutChartStyle(
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                  DonutChartSeries.fromMap(
                    id: 'inner',
                    values: const {'Previous': 100},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                    donutStyle: const DonutChartStyle(
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final rect = tester.getRect(find.byKey(const ValueKey('concentric-donut')));
    await tester.tapAt(rect.center + const Offset(140, 0));
    await tester.pump();
    await tester.tapAt(rect.center + const Offset(75, 0));
    await tester.pump();

    expect(tappedSeries, ['outer', 'inner']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'centers zero-offset inside labels within every allocated ring band',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 400,
                child: BravenChartPlus(
                  showLegend: false,
                  concentricDonutConfig: const ConcentricDonutConfig(
                    innerRadiusFactor: 0.25,
                    ringGap: 8,
                    ringWeights: {'outer': 1.5, 'inner': 1},
                  ),
                  theme: ChartTheme.light.copyWith(
                    pieChartTheme: const PieChartTheme(
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                  series: [
                    for (final id in const ['outer', 'inner'])
                      DonutChartSeries.fromMap(
                        id: id,
                        values: const {'Only': 100},
                        dataLabels: const PieDataLabelConfig(
                          position: PieDataLabelPosition.inside,
                          insideOffset: 0,
                        ),
                        donutStyle: const DonutChartStyle(
                          sliceGap: 0,
                          animationMode: PieAnimationMode.none,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      final rings = renderBox.debugElements
          .whereType<PieSeriesElement>()
          .toList(growable: false);
      expect(rings, hasLength(2));
      for (final ring in rings) {
        expect(ring.insideLabelRadiusFactor, 0.5);
        for (final slice in ring.geometry.slices) {
          final expectedRadius = (slice.innerRadius + slice.outerRadius) / 2;
          final actualRadius =
              (slice.insideLabelAnchor - slice.center).distance;
          expect(actualRadius, closeTo(expectedRadius, 1e-6));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps physical slice-gap sides parallel across every ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 400,
              child: BravenChartPlus(
                showLegend: false,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.25,
                  ringGap: 6,
                ),
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  for (final id in const ['outer', 'inner'])
                    DonutChartSeries.fromMap(
                      id: id,
                      values: const {'First': 1, 'Second': 1},
                      dataLabels: const PieDataLabelConfig(isVisible: false),
                      donutStyle: const DonutChartStyle(
                        startAngleDegrees: 0,
                        sliceGap: 10,
                        cornerRadius: 8,
                        animationMode: PieAnimationMode.none,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final rings = renderBox.debugElements.whereType<PieSeriesElement>().toList(
      growable: false,
    );
    expect(rings, hasLength(2));
    for (final ring in rings) {
      final first = ring.geometry.slices.first;
      final second = ring.geometry.slices.last;
      final boundaryAngle = first.startAngle + first.sweepAngle;
      final radial = Offset.fromDirection(boundaryAngle, 1);
      final normal = Offset(-radial.dy, radial.dx);
      final inset = ring.series.radialStyle.sliceGap / 2;
      final innerLineDistance = math.sqrt(
        first.innerRadius * first.innerRadius - inset * inset,
      );
      final outerLineDistance = math.sqrt(
        first.outerRadius * first.outerRadius - inset * inset,
      );
      for (final fraction in const [0.4, 0.6]) {
        final distance =
            innerLineDistance +
            (outerLineDistance - innerLineDistance) * fraction;
        final boundary = first.center + radial * distance;
        expect(first.contains(boundary - normal * (inset + 0.1)), isTrue);
        expect(first.contains(boundary - normal * (inset - 0.1)), isFalse);
        expect(second.contains(boundary + normal * (inset + 0.1)), isTrue);
        expect(second.contains(boundary + normal * (inset - 0.1)), isFalse);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lifted inner selection owns composition paint and hit priority',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final baseTheme = ChartTheme.light;
      final theme = baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          interactionDuration: Duration.zero,
          dataUpdateDuration: Duration.zero,
        ),
        pieChartTheme: const PieChartTheme(
          animationMode: PieAnimationMode.none,
        ),
      );
      const selectionStyle = RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.5,
        liftOffset: 20,
        backdropBlur: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 400,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  concentricDonutConfig: const ConcentricDonutConfig(
                    innerRadiusFactor: 0.25,
                    ringGap: 2,
                  ),
                  theme: theme,
                  series: [
                    DonutChartSeries.fromMap(
                      id: 'outer',
                      values: const {'Shared': 100},
                      selectionStyle: selectionStyle,
                      dataLabels: const PieDataLabelConfig(isVisible: false),
                    ),
                    DonutChartSeries.fromMap(
                      id: 'inner',
                      values: const {'Shared': 100},
                      selectionStyle: selectionStyle,
                      dataLabels: const PieDataLabelConfig(isVisible: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      ChartRenderBox renderBox() =>
          tester.allRenderObjects.whereType<ChartRenderBox>().single;
      List<PieSeriesElement> rings() => renderBox().debugElements
          .whereType<PieSeriesElement>()
          .toList(growable: false);
      final before = rings();
      final allocations = [
        for (final ring in before)
          (
            ring.geometry.center,
            ring.geometry.innerRadius,
            ring.geometry.outerRadius,
          ),
      ];

      final result = controller.selectPoint(
        const ChartPointRef(seriesId: 'inner', pointIndex: 0),
        revision: controller.effectiveDocumentRevision.value!,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final after = rings();
      final outer = after.singleWhere(
        (element) => element.series.id == 'outer',
      );
      final inner = after.singleWhere(
        (element) => element.series.id == 'inner',
      );
      expect([
        for (final ring in after)
          (
            ring.geometry.center,
            ring.geometry.innerRadius,
            ring.geometry.outerRadius,
          ),
      ], allocations);
      expect(inner.usesLiftSelection, isTrue);
      expect(inner.priority, greaterThan(outer.priority));
      expect(inner.compositionBackdropBlur, 2);
      expect(outer.compositionBackdropBlur, 2);

      final selectedAnchor = inner.geometry.slices.single.tooltipAnchor;
      expect(outer.sliceAt(selectedAnchor), isNotNull);
      final hit = renderBox().dataHitAtWidgetPosition(
        renderBox().plotToWidget(selectedAnchor),
      );
      expect(hit?.seriesId, 'inner');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fits constrained ring gaps and keeps selected paint inside the plot',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final baseTheme = ChartTheme.light;
      const selectedElevation = PieElevationStyle(
        blurRadius: 12,
        spreadRadius: 3,
        offset: Offset(3, 4),
        opacity: 0.5,
      );
      final theme = baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          interactionDuration: Duration.zero,
          dataUpdateDuration: Duration.zero,
        ),
        pieChartTheme: const PieChartTheme(
          animationMode: PieAnimationMode.none,
          selectedElevation: selectedElevation,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 180,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  concentricDonutConfig: const ConcentricDonutConfig(
                    innerRadiusFactor: 0.4,
                    outerRadiusFactor: 0.5,
                    ringGap: 12,
                  ),
                  theme: theme,
                  series: [
                    for (var index = 0; index < 4; index++)
                      DonutChartSeries.fromMap(
                        id: 'ring-$index',
                        values: const {'Primary': 70, 'Context': 30},
                        dataLabels: const PieDataLabelConfig(isVisible: false),
                        donutStyle: const DonutChartStyle(
                          selectionExplodeOffset: 18,
                          selectedElevation: selectedElevation,
                          animationMode: PieAnimationMode.none,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      ChartRenderBox renderBox() =>
          tester.allRenderObjects.whereType<ChartRenderBox>().single;
      List<PieSeriesElement> rings() => renderBox().debugElements
          .whereType<PieSeriesElement>()
          .toList(growable: false);

      final before = rings();
      expect(before, hasLength(4));
      expect(
        before.every(
          (ring) =>
              ring.geometry.outerRadius > ring.geometry.innerRadius &&
              ring.geometry.slices.isNotEmpty &&
              ring.coordinateOutsideLabels,
        ),
        isTrue,
      );
      final allocations = [
        for (final ring in before)
          (
            ring.geometry.center,
            ring.geometry.innerRadius,
            ring.geometry.outerRadius,
          ),
      ];

      final selection = controller.selectPoint(
        const ChartPointRef(seriesId: 'ring-0', pointIndex: 0),
        revision: controller.effectiveDocumentRevision.value!,
      );
      expect(selection, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final after = rings();
      expect([
        for (final ring in after)
          (
            ring.geometry.center,
            ring.geometry.innerRadius,
            ring.geometry.outerRadius,
          ),
      ], allocations);

      final selectedSlice = after.first.geometry.slices.first;
      final pathBounds = selectedSlice.path.getBounds();
      final elevationExtent =
          selectedElevation.spreadRadius + selectedElevation.blurRadius * 0.65;
      final paintBounds = Rect.fromLTRB(
        pathBounds.left - elevationExtent,
        pathBounds.top - elevationExtent,
        pathBounds.right + elevationExtent + selectedElevation.offset.dx,
        pathBounds.bottom + elevationExtent + selectedElevation.offset.dy,
      );
      final plotBounds = Offset.zero & after.first.size;
      expect(plotBounds.contains(paintBounds.topLeft), isTrue);
      expect(plotBounds.contains(paintBounds.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'groups legend items by ring and preserves series-qualified selection',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final builtItems = <RadialLegendItemData>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 760,
              height: 620,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: true,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.25,
                  ringGap: 4,
                ),
                radialLegendItemBuilder: (context, item) {
                  builtItems.add(item);
                  return SizedBox(
                    width: 168,
                    child: Text(
                      '${item.category} · ${item.shareLabel}',
                      maxLines: 1,
                    ),
                  );
                },
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'current',
                    name: 'Current period',
                    values: const {'Subscriptions': 60, 'Services': 40},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                    donutStyle: const DonutChartStyle(
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                  DonutChartSeries.fromMap(
                    id: 'previous',
                    name: 'Previous period',
                    values: const {'Subscriptions': 50, 'Services': 150},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                    donutStyle: const DonutChartStyle(
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outer ring · Current period'), findsOneWidget);
      expect(find.text('Inner ring · Previous period'), findsOneWidget);
      final previousSubscriptions = builtItems.lastWhere(
        (item) =>
            item.seriesId == 'previous' && item.category == 'Subscriptions',
      );
      expect(previousSubscriptions.ringIndex, 1);
      expect(previousSubscriptions.ringCount, 2);
      expect(previousSubscriptions.ringPositionLabel, 'Inner ring');
      expect(previousSubscriptions.ringTotal, 200);

      final extracted = controller.extractDocument();
      expect(extracted, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
      final snapshot =
          (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.hasMultipleRadialSeries, isTrue);
      expect(table.pieRows.map((row) => row.shareDisplay), [
        '60.00%',
        '40.00%',
        '25.00%',
        '75.00%',
      ]);

      final legendFinder = find.byKey(
        const ValueKey('concentric-donut-legend'),
      );
      final itemFinder = find.byKey(
        const ValueKey('pie-legend-item-previous-0'),
      );
      final legendBefore = tester.getRect(legendFinder);
      final itemBefore = tester.getRect(itemFinder);

      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'previous', pointIndex: 0),
      });
      expect(tester.getRect(legendFinder), legendBefore);
      expect(tester.getRect(itemFinder), itemBefore);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grouped Other selection stays inside its ring across table legend and restore',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ConcentricGroupedTableSelectionHost(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('current:1')));
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'current', pointIndex: 1),
        const ChartPointRef(seriesId: 'current', pointIndex: 2),
        const ChartPointRef(seriesId: 'current', pointIndex: 3),
      });
      for (final index in <int>[1, 2, 3]) {
        expect(
          tester
              .getSemantics(find.byKey(ValueKey<String>('current:$index')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(find.byKey(ValueKey<String>('previous:$index')))
              .flagsCollection
              .isSelected,
          isNot(Tristate.isTrue),
        );
      }

      await tester.tap(
        find.byKey(const ValueKey<String>('pie-legend-item-previous-1-2-3')),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'previous', pointIndex: 1),
        const ChartPointRef(seriesId: 'previous', pointIndex: 2),
        const ChartPointRef(seriesId: 'previous', pointIndex: 3),
      });
      expect(
        find.semantics.byLabel(
          'Inner ring, Previous period, Other, 20.00 USD, 20.0 percent, '
          '3 grouped categories, slice 2 of 2, selected',
        ),
        findsOne,
      );

      controller.clearPointSelection();
      await tester.pumpAndSettle();
      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      final currentRing = renderBox.debugElements
          .whereType<PieSeriesElement>()
          .singleWhere((element) => element.series.id == 'current');
      await tester.tapAt(
        renderBox.localToGlobal(currentRing.geometry.slices.last.tooltipAnchor),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'current', pointIndex: 1),
        const ChartPointRef(seriesId: 'current', pointIndex: 2),
        const ChartPointRef(seriesId: 'current', pointIndex: 3),
      });

      final controllerSelection = controller.selectPoint(
        const ChartPointRef(seriesId: 'previous', pointIndex: 2),
        revision: controller.effectiveDocumentRevision.value!,
      );
      expect(controllerSelection, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'previous', pointIndex: 1),
        const ChartPointRef(seriesId: 'previous', pointIndex: 2),
        const ChartPointRef(seriesId: 'previous', pointIndex: 3),
      });

      controller.restoreViewState(
        ChartViewState(
          selectedPointRefs: const [
            ChartPointRef(seriesId: 'current', pointIndex: 2),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'current', pointIndex: 1),
        const ChartPointRef(seriesId: 'current', pointIndex: 2),
        const ChartPointRef(seriesId: 'current', pointIndex: 3),
      });
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('flat legend keeps ring identity in every default item', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 620,
            child: BravenChartPlus(
              showLegend: true,
              concentricDonutConfig: const ConcentricDonutConfig(
                innerRadiusFactor: 0.25,
                ringGap: 4,
                legendMode: ConcentricDonutLegendMode.flat,
              ),
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: [
                DonutChartSeries.fromMap(
                  id: 'current',
                  name: 'Current period',
                  values: const {'Subscriptions': 100},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
                DonutChartSeries.fromMap(
                  id: 'previous',
                  name: 'Previous period',
                  values: const {'Subscriptions': 200},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outer ring · Current period'), findsNothing);
    expect(find.text('Inner ring · Previous period'), findsNothing);
    expect(find.text('Current period · Subscriptions'), findsOneWidget);
    expect(find.text('Previous period · Subscriptions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'repeated categories retain ring context in tooltips and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 460,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: false,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.25,
                  ringGap: 4,
                ),
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'current',
                    name: 'Current period',
                    unit: 'USD',
                    values: const {'Subscriptions': 60, 'Services': 40},
                    dataLabels: PieDataLabelConfig(
                      isVisible: false,
                      valueFormatter: (value) =>
                          'Current ${value.toStringAsFixed(0)} USD',
                      percentageFormatter: (share) =>
                          'Current ${(share * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                  DonutChartSeries.fromMap(
                    id: 'previous',
                    name: 'Previous period',
                    unit: 'USD',
                    values: const {'Subscriptions': 50, 'Services': 150},
                    dataLabels: PieDataLabelConfig(
                      isVisible: false,
                      valueFormatter: (value) =>
                          'Previous ${value.toStringAsFixed(0)} USD',
                      percentageFormatter: (share) =>
                          'Previous ${(share * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final revision = controller.effectiveDocumentRevision.value!;
      final selection = controller.selectPoint(
        const ChartPointRef(seriesId: 'previous', pointIndex: 0),
        revision: revision,
      );
      expect(selection, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      final hit = renderBox.debugSelectedTooltipMarker!.dataHit!;
      expect(hit.groupLabel, 'Inner ring');
      expect(hit.groupName, 'Previous period');
      expect(hit.groupOrdinal, 2);
      expect(hit.groupCount, 2);
      expect(hit.formattedValue, 'Previous 50 USD');
      expect(hit.formattedShare, 'Previous 25%');
      expect(
        hit.semanticLabel,
        'Inner ring, Previous period, Subscriptions, Previous 50 USD, '
        'Previous 25 percent, slice 1 of 2, selected',
      );
      expect(find.semantics.byLabel(hit.semanticLabel), findsOne);
      expect(
        find.semantics.byLabel(
          'Concentric Donut chart with 2 rings and 4 slices',
        ),
        findsOne,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('keyboard traversal crosses the ring boundary with exact refs', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 460,
            child: BravenChartPlus(
              key: const ValueKey('keyboard-concentric-donut'),
              bravenChartController: controller,
              showLegend: false,
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: [
                DonutChartSeries.fromMap(
                  id: 'outer',
                  values: const {'A': 60, 'B': 40},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
                DonutChartSeries.fromMap(
                  id: 'inner',
                  values: const {'A': 30, 'B': 70},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = find.byKey(const ValueKey('keyboard-concentric-donut'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getTopLeft(chart));
    await mouse.moveTo(tester.getCenter(chart) + const Offset(130, 0));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'inner', pointIndex: 0),
    });
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets(
    'paints one composition-owned portable center and ignores ring centers',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 460,
              child: BravenChartPlus(
                showLegend: false,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.3,
                  centerContent: DonutCenterContent(
                    label: 'Comparison',
                    valueMode: DonutCenterValueMode.custom,
                    customValue: '2 periods',
                  ),
                ),
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'current',
                    values: const {'Subscriptions': 60, 'Services': 40},
                    centerContent: const DonutCenterContent(
                      label: 'Wrong current center',
                      valueMode: DonutCenterValueMode.custom,
                      customValue: 'wrong',
                    ),
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                  DonutChartSeries.fromMap(
                    id: 'previous',
                    values: const {'Subscriptions': 50, 'Services': 150},
                    centerContent: const DonutCenterContent(
                      label: 'Wrong previous center',
                      valueMode: DonutCenterValueMode.custom,
                      customValue: 'wrong',
                    ),
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel('Donut center, Comparison, 2 periods'),
        findsOne,
      );
      expect(
        find.semantics.byLabel(RegExp(r'Wrong (current|previous) center')),
        findsNothing,
      );
      expect(find.semantics.byLabel(RegExp(r'^Donut center,')), findsOne);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('dark radial title and center defaults ignore light host theme', (
    tester,
  ) async {
    DonutCenterData? centerData;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: SizedBox.square(
            dimension: 520,
            child: BravenChartPlus(
              title: 'Dark radial title',
              subtitle: 'Dark radial subtitle',
              showLegend: false,
              concentricDonutConfig: const ConcentricDonutConfig(
                centerContent: DonutCenterContent(
                  valueMode: DonutCenterValueMode.selectedOrTotal,
                ),
              ),
              donutCenterBuilder: (context, center) {
                centerData = center;
                return const SizedBox.shrink();
              },
              theme: ChartTheme.dark.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: [
                DonutChartSeries.fromMap(
                  id: 'current-dark',
                  name: 'Current period',
                  values: const {'A': 60, 'B': 40},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
                DonutChartSeries.fromMap(
                  id: 'previous-dark',
                  name: 'Previous period',
                  values: const {'A': 50, 'B': 50},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Dark radial title'));
    final subtitle = tester.widget<Text>(find.text('Dark radial subtitle'));
    expect(title.style?.color, ChartTheme.dark.axisStyle.titleStyle.color);
    expect(subtitle.style?.color, ChartTheme.dark.axisStyle.labelStyle.color);
    expect(
      centerData?.defaultLabelStyle.color,
      ChartTheme.dark.axisStyle.labelStyle.color,
    );
    expect(
      centerData?.defaultValueStyle.color,
      ChartTheme.dark.axisStyle.labelStyle.color,
    );
    expect(centerData?.label, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('readable host title colors remain unchanged', (tester) async {
    const hostTitle = Color(0xFF12304A);
    const hostSubtitle = Color(0xFF24513A);
    final baseTextTheme = ThemeData.light().textTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          textTheme: baseTextTheme.copyWith(
            titleLarge: baseTextTheme.titleLarge?.copyWith(color: hostTitle),
            titleSmall: baseTextTheme.titleSmall?.copyWith(color: hostSubtitle),
          ),
        ),
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              title: 'Readable host title',
              subtitle: 'Readable host subtitle',
              showLegend: false,
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: [
                PieChartSeries.fromMap(
                  id: 'host-color-pie',
                  values: const {'A': 60, 'B': 40},
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('Readable host title')).style?.color,
      hostTitle,
    );
    expect(
      tester.widget<Text>(find.text('Readable host subtitle')).style?.color,
      hostSubtitle,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text high-contrast composition stays bounded with reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(560, 460);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
              highContrast: true,
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: SizedBox(
            width: 560,
            height: 460,
            child: BravenChartPlus(
              showLegend: false,
              concentricDonutConfig: const ConcentricDonutConfig(
                innerRadiusFactor: 0.3,
                ringGap: 5,
                centerContent: DonutCenterContent(
                  label: 'Periods',
                  valueMode: DonutCenterValueMode.custom,
                  customValue: '2 compared',
                ),
              ),
              theme: ChartTheme.highContrast,
              series: [
                DonutChartSeries.fromMap(
                  id: 'current-accessible',
                  name: 'Current period',
                  unit: 'requests',
                  values: const {'Accounts': 60, 'Support': 40},
                  dataLabels: const PieDataLabelConfig(
                    position: PieDataLabelPosition.outside,
                    content: PieDataLabelContent.categoryAndPercentage,
                    minimumShare: 0,
                  ),
                  donutStyle: const DonutChartStyle(
                    animationMode: PieAnimationMode.sweep,
                  ),
                ),
                DonutChartSeries.fromMap(
                  id: 'previous-accessible',
                  name: 'Previous period',
                  unit: 'requests',
                  values: const {'Accounts': 55, 'Support': 45},
                  dataLabels: const PieDataLabelConfig(
                    position: PieDataLabelPosition.outside,
                    content: PieDataLabelContent.categoryAndPercentage,
                    minimumShare: 0,
                  ),
                  donutStyle: const DonutChartStyle(
                    animationMode: PieAnimationMode.sweep,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.semantics.byLabel('Donut center, Periods, 2 compared'),
        findsOne,
      );
      expect(
        find.semantics.byLabel(
          RegExp(r'^Outer ring, Current period, Accounts,'),
        ),
        findsOne,
      );
      expect(
        find.semantics.byLabel(
          RegExp(r'^Inner ring, Previous period, Accounts,'),
        ),
        findsOne,
      );
      expect(
        tester.getSize(find.byType(BravenChartPlus)),
        const Size(560, 460),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'runtime center receives every ring and exact selected ring identity',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      DonutCenterData? latestCenter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 520,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: true,
                concentricDonutConfig: const ConcentricDonutConfig(
                  innerRadiusFactor: 0.3,
                  centerContent: DonutCenterContent(
                    label: 'Periods',
                    valueMode: DonutCenterValueMode.selectedOrTotal,
                  ),
                ),
                donutCenterBuilder: (context, center) {
                  latestCenter = center;
                  return Center(
                    key: const ValueKey('concentric-runtime-center'),
                    child: Text(center.selectedSeriesId ?? 'All rings'),
                  );
                },
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'current',
                    name: 'Current period',
                    unit: 'USD',
                    values: const {'Subscriptions': 60, 'Services': 40},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                  DonutChartSeries.fromMap(
                    id: 'previous',
                    name: 'Previous period',
                    unit: 'USD',
                    values: const {'Subscriptions': 50, 'Services': 150},
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('concentric-runtime-center')), findsOne);
      expect(find.text('All rings'), findsOneWidget);
      expect(latestCenter?.total, 100);
      expect(latestCenter?.rings, hasLength(2));
      expect(
        latestCenter?.rings
            .map((ring) => (ring.seriesId, ring.total, ring.positionLabel))
            .toList(),
        [('current', 100.0, 'Outer ring'), ('previous', 200.0, 'Inner ring')],
      );

      final revision = controller.effectiveDocumentRevision.value!;
      final selection = controller.selectPoint(
        const ChartPointRef(seriesId: 'previous', pointIndex: 1),
        revision: revision,
      );
      expect(selection, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      expect(find.text('previous'), findsOneWidget);
      expect(latestCenter?.selectedSeriesId, 'previous');
      expect(latestCenter?.selectedRingIndex, 1);
      expect(latestCenter?.selectedPointIndex, 1);
      expect(latestCenter?.selectedCategory, 'Services');
      expect(latestCenter?.selectedValue, 150);
      expect(latestCenter?.selectedShare, 0.75);
      expect(latestCenter?.total, 200);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ConcentricGroupedTableSelectionHost extends StatelessWidget {
  const _ConcentricGroupedTableSelectionHost({required this.controller});

  final BravenChartController controller;

  @override
  Widget build(BuildContext context) {
    final rings = _groupedSeries();
    final documents = <ChartSeriesDocument>[
      for (final ring in rings)
        (ChartSeriesDocumentCodec.encode(ring)
                as ChartArtifactSuccess<ChartSeriesDocument>)
            .value,
    ];
    final model = ChartTableModel.fromDocument(
      ChartDocument(
        documentId: 'concentric-grouped-selection',
        revision: 1,
        series: documents,
        xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
        axes: const [],
        theme:
            (ChartThemeDocumentCodec.encode(ChartTheme.light)
                    as ChartArtifactSuccess<ChartThemeDocument>)
                .value,
        interaction:
            (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                    as ChartArtifactSuccess<ChartInteractionDocument>)
                .value,
      ),
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: BravenChartPlus(
              bravenChartController: controller,
              showLegend: true,
              concentricDonutConfig: const ConcentricDonutConfig(
                innerRadiusFactor: 0.28,
                ringGap: 4,
              ),
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: rings,
            ),
          ),
          Expanded(
            child: ChartDataTable(
              model: model,
              selectedPointRefs: controller.selectedPointRefs,
              onRowActivated: (points) {
                final revision = controller.effectiveDocumentRevision.value;
                if (revision == null) return;
                controller.selectPoints(points, revision: revision);
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<DonutChartSeries> _groupedSeries() => [
  DonutChartSeries.fromMap(
    id: 'current',
    name: 'Current period',
    unit: 'USD',
    values: const {'Core': 80, 'Email': 8, 'Chat': 7, 'Other source': 5},
    sliceGroupingConfig: const RadialSliceGroupingConfig(minimumShare: 0.1),
    dataLabels: const PieDataLabelConfig(isVisible: false),
    donutStyle: const DonutChartStyle(animationMode: PieAnimationMode.none),
  ),
  DonutChartSeries.fromMap(
    id: 'previous',
    name: 'Previous period',
    unit: 'USD',
    values: const {'Core': 80, 'Email': 8, 'Chat': 7, 'Other source': 5},
    sliceGroupingConfig: const RadialSliceGroupingConfig(minimumShare: 0.1),
    dataLabels: const PieDataLabelConfig(isVisible: false),
    donutStyle: const DonutChartStyle(animationMode: PieAnimationMode.none),
  ),
];
