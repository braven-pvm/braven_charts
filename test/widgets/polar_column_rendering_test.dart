import 'dart:ui' show PointerDeviceKind;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:braven_charts/src/layout/polar_column_composition.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects absolute intervals on cumulative stacked contributors', () {
    final intervalSeries = PolarColumnChartSeries.fromMap(
      id: 'estimate',
      unit: 'orders',
      values: const {'Search': 30},
      intervals: const {'Search': PolarColumnInterval(lower: 24, upper: 36)},
    );
    final contributor = PolarColumnChartSeries.fromMap(
      id: 'increment',
      unit: 'orders',
      values: const {'Search': 12},
    );

    expect(
      () => PolarColumnComposition.validate(
        [intervalSeries, contributor],
        config: const PolarChartConfig(
          composition: PolarColumnCompositionConfig(
            mode: PolarColumnCompositionMode.stacked,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('renders Polar Column through BravenChartPlus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'orders',
                  values: const {
                    'Search': 64,
                    'Social': 28,
                    'Partners': 45,
                    'Email': 16,
                  },
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
              ),
              theme: ChartTheme.light,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.geometry.marks, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer activation selects a Polar Column mark', (tester) async {
    List<ChartDataPoint> selection = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 360,
              child: BravenChartPlus(
                series: [
                  PolarColumnChartSeries.fromMap(
                    id: 'orders',
                    values: const {'Search': 64, 'Social': 28},
                  ),
                ],
                polarChartConfig: const PolarChartConfig(
                  angularAxis: PolarCategoryAxisConfig(showLabels: false),
                ),
                interactionConfig: InteractionConfig(
                  onSelectionChanged: (points) => selection = points,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chartFinder = find.byType(BravenChartPlus);
    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    final localTarget = renderBox.plotToWidget(
      element.geometry.marks.first.tooltipAnchor,
    );
    await tester.tapAt(tester.getTopLeft(chartFinder) + localTarget);
    await tester.pump();

    expect(selection, hasLength(1));
    expect(selection.single.label, 'Search');
    expect(tester.takeException(), isNull);
  });

  testWidgets('layers compatible series on one scale in declaration order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'target',
                  name: 'Target',
                  unit: 'orders',
                  values: const {'Search': 100, 'Social': 80},
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'observed',
                  name: 'Observed',
                  unit: 'orders',
                  values: const {'Search': 64, 'Social': 48},
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
              ),
              theme: ChartTheme.light,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final elements = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .toList();
    expect(elements, hasLength(2));
    expect(elements.map((element) => element.series.id), [
      'target',
      'observed',
    ]);
    expect(elements.map((element) => element.numericScale.maximum).toSet(), {
      100,
    });
    expect(elements.first.paintGrid, isTrue);
    expect(elements.first.paintAxisLabels, isFalse);
    expect(elements.last.paintGrid, isFalse);
    expect(elements.last.paintAxisLabels, isTrue);

    final hit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(elements.last.geometry.marks.first.tooltipAnchor),
    );
    expect(hit?.seriesId, 'observed');
    expect(hit?.category, 'Search');
    expect(tester.takeException(), isNull);
  });

  testWidgets('targets and thresholds extend the automatic radial domain', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'actual',
                  values: const {'Search': 40, 'Social': 55},
                  targets: const {'Search': 70, 'Social': 65},
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                thresholds: <PolarThreshold>[
                  PolarThreshold(value: 120, label: 'Capacity'),
                ],
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.numericScale.maximum, 120);
    expect(element.geometry.marks.first.targetValue, 70);
    expect(element.geometry.marks.first.targetPath, isNotNull);

    final hit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(element.geometry.marks.first.tooltipAnchor),
    );
    expect(hit?.formattedValue, contains('target 70'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard traversal preserves series identity across layers', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              key: const ValueKey('layered-polar-keyboard'),
              bravenChartController: controller,
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'target',
                  unit: 'orders',
                  values: const {'Search': 100, 'Social': 80},
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'observed',
                  unit: 'orders',
                  values: const {'Search': 64, 'Social': 48},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chart = find.byKey(const ValueKey('layered-polar-keyboard'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getTopLeft(chart));
    await mouse.moveTo(tester.getCenter(chart));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'observed', pointIndex: 0),
    });
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets('groups compatible series into separate category sub-bands', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'north',
                  unit: 'orders',
                  values: const {'Search': 80, 'Social': 55},
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'south',
                  unit: 'orders',
                  values: const {'Search': 64, 'Social': 72},
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
                composition: PolarColumnCompositionConfig(
                  mode: PolarColumnCompositionMode.grouped,
                  groupInnerPadding: 0.18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final elements = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .toList();
    expect(elements, hasLength(2));
    final northMark = elements[0].geometry.marks.first;
    final southMark = elements[1].geometry.marks.first;
    expect(northMark.band.endAngle, lessThan(southMark.band.startAngle));
    expect(northMark.band.centerAngle, isNot(southMark.band.centerAngle));
    expect(elements.map((element) => element.numericScale.maximum).toSet(), {
      80,
    });

    final northHit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(northMark.tooltipAnchor),
    );
    final southHit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(southMark.tooltipAnchor),
    );
    expect(northHit?.seriesId, 'north');
    expect(southHit?.seriesId, 'south');
    expect(northHit?.category, 'Search');
    expect(southHit?.category, 'Search');
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks signed contributors independently from zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 440,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'new',
                  unit: 'accounts',
                  values: const {'Search': 30, 'Social': 20},
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'expansion',
                  unit: 'accounts',
                  values: const {'Search': 12, 'Social': 8},
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'churn',
                  unit: 'accounts',
                  values: const {'Search': -15, 'Social': -24},
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                pane: PolarPaneConfig(innerRadiusFactor: 0.12),
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
                composition: PolarColumnCompositionConfig(
                  mode: PolarColumnCompositionMode.stacked,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final elements = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .toList();
    expect(elements, hasLength(3));
    expect(elements.map((element) => element.numericScale.minimum).toSet(), {
      -24,
    });
    expect(elements.map((element) => element.numericScale.maximum).toSet(), {
      42,
    });
    expect(elements.map((element) => element.baseline).toSet(), {0});

    final newSearch = elements[0].geometry.marks[0];
    final expansionSearch = elements[1].geometry.marks[0];
    final churnSocial = elements[2].geometry.marks[1];
    expect(newSearch.baseline, 0);
    expect(newSearch.radialValue, 30);
    expect(expansionSearch.baseline, 30);
    expect(expansionSearch.radialValue, 42);
    expect(churnSocial.baseline, 0);
    expect(churnSocial.radialValue, -24);

    for (final (mark, seriesId) in [
      (newSearch, 'new'),
      (expansionSearch, 'expansion'),
      (churnSocial, 'churn'),
    ]) {
      final hit = renderBox.dataHitAtWidgetPosition(
        renderBox.plotToWidget(mark.tooltipAnchor),
      );
      expect(hit?.seriesId, seriesId);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders intervals and includes their endpoints in auto domain', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'forecast',
                  unit: 'orders',
                  values: const {'Search': 62, 'Social': 48},
                  intervals: const {
                    'Search': PolarColumnInterval(lower: 54, upper: 91),
                    'Social': PolarColumnInterval(lower: 39, upper: 57),
                  },
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.numericScale.maximum, 91);
    expect(
      element.geometry.marks.every((mark) => mark.intervalWhiskerPath != null),
      isTrue,
    );
    final hit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(element.geometry.marks.first.tooltipAnchor),
    );
    expect(hit?.formattedValue, contains('interval 54 orders to 91 orders'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors large text while preserving complete semantic data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 240,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'dense',
                  values: {
                    for (var index = 0; index < 16; index++)
                      'Category ${index + 1}': 20 + index,
                  },
                ),
              ],
              theme: ChartTheme.highContrast,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.textScaleFactor, 1.6);
    expect(element.visibleAngularLabelIndices.length, lessThan(16));
    expect(element.semanticDataHits, hasLength(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion resolves Polar Column at its final geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox.square(
            dimension: 320,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'reduced-motion',
                  values: const {'North': 12, 'East': 24, 'South': 18},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.revealProgress, 1);
    expect(element.geometry.marks.every((mark) => mark.isVisible), isTrue);
    expect(tester.takeException(), isNull);
  });
}
