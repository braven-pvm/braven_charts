import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
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
    expect(elements.skip(1).every((element) => !element.paintGrid), isTrue);
    expect(elements.every((element) => !element.paintAxisLabels), isTrue);
    expect(elements.every((element) => !element.paintDataLabels), isTrue);
    final overlay = renderBox.debugElements
        .whereType<PolarColumnCompositionOverlayElement>()
        .single;
    expect(overlay.seriesElements, elements);
    expect(overlay.priority, greaterThan(elements.last.priority));

    final hit = renderBox.dataHitAtWidgetPosition(
      renderBox.plotToWidget(elements.last.geometry.marks.first.tooltipAnchor),
    );
    expect(hit?.seriesId, 'observed');
    expect(hit?.category, 'Search');
    expect(tester.takeException(), isNull);
  });

  for (final effect in RadialSelectionEffect.values) {
    testWidgets(
      'selected inner stacked mark paints above outer marks for ${effect.name}',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.square(
                dimension: 420,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  series: [
                    PolarColumnChartSeries.fromMap(
                      id: 'inner',
                      unit: 'units',
                      values: const {'Search': 18, 'Social': 16},
                      color: Colors.green,
                      polarStyle: const PolarColumnStyle(showDataLabels: false),
                      selectionStyle: RadialSelectionStyle(
                        effect: effect,
                        liftScale: 1.12,
                        liftOffset: 60,
                      ),
                    ),
                    PolarColumnChartSeries.fromMap(
                      id: 'middle',
                      unit: 'units',
                      values: const {'Search': 26, 'Social': 24},
                      color: Colors.blue,
                      polarStyle: const PolarColumnStyle(showDataLabels: false),
                    ),
                    PolarColumnChartSeries.fromMap(
                      id: 'outer',
                      unit: 'units',
                      values: const {'Search': 14, 'Social': 12},
                      color: Colors.red,
                      polarStyle: const PolarColumnStyle(showDataLabels: false),
                    ),
                  ],
                  polarChartConfig: const PolarChartConfig(
                    angularAxis: PolarCategoryAxisConfig(showLabels: false),
                    radialAxis: PolarNumericAxisConfig(showLabels: false),
                    composition: PolarColumnCompositionConfig(
                      mode: PolarColumnCompositionMode.stacked,
                    ),
                  ),
                  theme: ChartTheme.light.copyWith(
                    gridStyle: ChartTheme.light.gridStyle.copyWith(
                      majorColor: Colors.transparent,
                    ),
                    axisStyle: ChartTheme.light.axisStyle.copyWith(
                      lineColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final revision = controller.effectiveDocumentRevision.value!;
        final result = controller.selectPoint(
          const ChartPointRef(seriesId: 'inner', pointIndex: 0),
          revision: revision,
        );
        expect(result, isA<ChartArtifactSuccess<void>>());
        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<ChartRenderBox>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        );
        final elements = renderBox.debugElements
            .whereType<PolarColumnSeriesElement>()
            .toList();
        final inner = elements.singleWhere(
          (element) => element.series.id == 'inner',
        );
        final outer = elements.singleWhere(
          (element) => element.series.id == 'outer',
        );
        final middle = elements.singleWhere(
          (element) => element.series.id == 'middle',
        );
        final overlay = renderBox.debugElements
            .whereType<PolarColumnCompositionOverlayElement>()
            .single;
        final paintOrder = <DataSeriesElement>[...elements, overlay]
          ..sort((a, b) {
            final priority = a.priority.compareTo(b.priority);
            return priority != 0
                ? priority
                : a.seriesIndex.compareTo(b.seriesIndex);
          });

        expect(inner.selectedPointIndices, {0});
        expect(inner.priority, greaterThan(outer.priority));
        expect(paintOrder[paintOrder.length - 2], same(inner));
        expect(paintOrder.last, same(overlay));

        final selectedPoint = inner.dataHitForPointIndex(0)!.plotPosition;
        expect(
          middle.geometry.marks.first.path.contains(selectedPoint),
          isTrue,
        );
        final rgb = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          for (final element in paintOrder) {
            element.paint(canvas, elements.first.size);
          }
          final image = await recorder.endRecording().toImage(
            elements.first.size.width.ceil(),
            elements.first.size.height.ceil(),
          );
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final x = selectedPoint.dx.round().clamp(0, image.width - 1);
          final y = selectedPoint.dy.round().clamp(0, image.height - 1);
          final offset = (y * image.width + x) * 4;
          final result = <int>[
            bytes!.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          ];
          image.dispose();
          return result;
        });
        final [red, green, blue] = rgb!;
        expect(green, greaterThan(red + 40));
        expect(green, greaterThan(blue + 40));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('stack exterior rounding reaches only signed terminal marks', (
    tester,
  ) async {
    PolarColumnChartSeries series(
      String id,
      Map<String, num> values,
      Color color,
    ) => PolarColumnChartSeries.fromMap(
      id: id,
      values: values,
      color: color,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 10,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        showDataLabels: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              series: [
                series('first', const {'A': 10, 'B': -4}, Colors.green),
                series('second', const {'A': -3, 'B': -6}, Colors.blue),
                series('third', const {'A': 5, 'B': 2}, Colors.red),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
                radialAxis: PolarNumericAxisConfig(showLabels: false),
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
    final first = elements.singleWhere(
      (element) => element.series.id == 'first',
    );
    final second = elements.singleWhere(
      (element) => element.series.id == 'second',
    );
    final third = elements.singleWhere(
      (element) => element.series.id == 'third',
    );

    expect(first.geometry.marks[0].sector.cornerRadius, 0);
    expect(first.geometry.marks[1].sector.cornerRadius, 0);
    expect(second.geometry.marks[0].sector.roundInnerCorners, isTrue);
    expect(second.geometry.marks[0].sector.roundOuterCorners, isFalse);
    expect(second.geometry.marks[1].sector.roundInnerCorners, isTrue);
    expect(third.geometry.marks[0].sector.roundOuterCorners, isTrue);
    expect(third.geometry.marks[1].sector.roundOuterCorners, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial-sweep grid uses one foreground composition pass', (
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
                  id: 'inner',
                  values: const {'Search': 42, 'Social': 38, 'Email': 44},
                  color: Colors.blue,
                  polarStyle: const PolarColumnStyle(showDataLabels: false),
                ),
                PolarColumnChartSeries.fromMap(
                  id: 'outer',
                  values: const {'Search': 18, 'Social': 16, 'Email': 20},
                  color: Colors.red,
                  polarStyle: const PolarColumnStyle(showDataLabels: false),
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                pane: PolarPaneConfig(sweepAngleDegrees: 110),
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
                composition: PolarColumnCompositionConfig(
                  mode: PolarColumnCompositionMode.stacked,
                ),
              ),
              theme: ChartTheme.light.copyWith(
                gridStyle: ChartTheme.light.gridStyle.copyWith(
                  majorColor: Colors.green,
                  majorWidth: 4,
                ),
                axisStyle: ChartTheme.light.axisStyle.copyWith(
                  lineColor: Colors.transparent,
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
    final overlay = renderBox.debugElements
        .whereType<PolarColumnCompositionOverlayElement>()
        .single;

    expect(elements, hasLength(2));
    expect(elements.first.paintGrid, isTrue);
    expect(elements.last.paintGrid, isFalse);
    expect(overlay.seriesElements, elements);
    expect(overlay.priority, greaterThan(elements.last.priority));
    expect(elements.first.pane.sweepAngle, closeTo(110 * math.pi / 180, 1e-9));

    final outer = elements.last;
    final gridPoint =
        outer.pane.center +
        Offset.fromDirection(
          outer.geometry.marks.first.band.centerAngle,
          outer.numericScale.valueToRadius(48),
        );
    expect(outer.geometry.marks.first.path.contains(gridPoint), isTrue);
    final paintOrder = <DataSeriesElement>[...elements, overlay]
      ..sort((a, b) {
        final priority = a.priority.compareTo(b.priority);
        return priority != 0
            ? priority
            : a.seriesIndex.compareTo(b.seriesIndex);
      });
    final greenChannels = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (final element in paintOrder) {
        element.paint(canvas, elements.first.size);
      }
      final image = await recorder.endRecording().toImage(
        elements.first.size.width.ceil(),
        elements.first.size.height.ceil(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final channels = <int>[];
      final centerX = gridPoint.dx.round();
      final centerY = gridPoint.dy.round();
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final x = (centerX + dx).clamp(0, image.width - 1);
          final y = (centerY + dy).clamp(0, image.height - 1);
          channels.add(bytes!.getUint8((y * image.width + x) * 4 + 1));
        }
      }
      image.dispose();
      return channels;
    });
    expect(greenChannels!.reduce(math.max), greaterThan(40));
    expect(tester.takeException(), isNull);
  });

  for (final startAngle in const <double>[40, 60, -135]) {
    testWidgets(
      'full-sweep radial grid stays closed at $startAngle degree start',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.square(
                dimension: 420,
                child: BravenChartPlus(
                  series: [
                    PolarColumnChartSeries.fromMap(
                      id: 'inner',
                      values: const {'A': 45, 'B': 45, 'C': 45, 'D': 45},
                      color: Colors.black,
                      polarStyle: const PolarColumnStyle(showDataLabels: false),
                    ),
                    PolarColumnChartSeries.fromMap(
                      id: 'outer',
                      values: const {'A': 45, 'B': 45, 'C': 45, 'D': 45},
                      color: Colors.black,
                      polarStyle: const PolarColumnStyle(showDataLabels: false),
                    ),
                  ],
                  polarChartConfig: PolarChartConfig(
                    pane: PolarPaneConfig(startAngleDegrees: startAngle),
                    angularAxis: const PolarCategoryAxisConfig(
                      innerPadding: 0,
                      outerPadding: 0,
                      showLabels: false,
                    ),
                    radialAxis: const PolarNumericAxisConfig(
                      tickCount: 5,
                      showLabels: false,
                    ),
                    composition: const PolarColumnCompositionConfig(
                      mode: PolarColumnCompositionMode.stacked,
                    ),
                  ),
                  theme: ChartTheme.light.copyWith(
                    gridStyle: ChartTheme.light.gridStyle.copyWith(
                      majorColor: Colors.green,
                      majorWidth: 4,
                    ),
                    axisStyle: ChartTheme.light.axisStyle.copyWith(
                      lineColor: Colors.transparent,
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
        final overlay = renderBox.debugElements
            .whereType<PolarColumnCompositionOverlayElement>()
            .single;
        final paintOrder = <DataSeriesElement>[...elements, overlay]
          ..sort((a, b) {
            final priority = a.priority.compareTo(b.priority);
            return priority != 0
                ? priority
                : a.seriesIndex.compareTo(b.seriesIndex);
          });
        final probeRadius = elements.first.numericScale.valueToRadius(45);

        final greenChannels = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder)
            ..drawColor(Colors.black, BlendMode.src);
          for (final element in paintOrder) {
            element.paint(canvas, elements.first.size);
          }
          final image = await recorder.endRecording().toImage(
            elements.first.size.width.ceil(),
            elements.first.size.height.ceil(),
          );
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final channels = <int>[];
          for (final angle in const <double>[
            0,
            math.pi / 2,
            math.pi,
            math.pi * 1.5,
          ]) {
            final point =
                elements.first.pane.center +
                Offset.fromDirection(angle, probeRadius);
            var maximum = 0;
            for (var dy = -2; dy <= 2; dy++) {
              for (var dx = -2; dx <= 2; dx++) {
                final x = (point.dx.round() + dx).clamp(0, image.width - 1);
                final y = (point.dy.round() + dy).clamp(0, image.height - 1);
                maximum = math.max(
                  maximum,
                  bytes!.getUint8((y * image.width + x) * 4 + 1),
                );
              }
            }
            channels.add(maximum);
          }
          image.dispose();
          return channels;
        });

        expect(greenChannels, everyElement(greaterThan(40)));
        expect(tester.takeException(), isNull);
      },
    );
  }

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
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
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

  testWidgets(
    'Polar Column grow entrance repaints from baseline to completion',
    (tester) async {
      final baseTheme = ChartTheme.light;
      final theme = baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          dataUpdateDuration: const Duration(milliseconds: 400),
          dataUpdateCurve: Curves.linear,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 320,
              child: BravenChartPlus(
                theme: theme,
                series: [
                  PolarColumnChartSeries.fromMap(
                    id: 'grow-entrance',
                    values: const {'North': 12, 'East': 24, 'South': 18},
                    polarStyle: const PolarColumnStyle(
                      animationMode: PolarColumnAnimationMode.grow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      PolarColumnSeriesElement element() => tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single
          .debugElements
          .whereType<PolarColumnSeriesElement>()
          .single;

      await tester.pump();
      expect(element().revealProgress, 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(element().revealProgress, closeTo(0.5, 0.02));
      expect(element().geometry.marks.every((mark) => mark.isVisible), isTrue);

      await tester.pumpAndSettle();
      expect(element().revealProgress, 1);
      expect(element().geometry.marks.every((mark) => mark.isVisible), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Polar Column sweep entrance advances around the stable pane', (
    tester,
  ) async {
    final baseTheme = ChartTheme.light;
    final theme = baseTheme.copyWith(
      animationTheme: baseTheme.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 320,
            child: BravenChartPlus(
              theme: theme,
              polarChartConfig: const PolarChartConfig(
                pane: PolarPaneConfig(
                  startAngleDegrees: 35,
                  sweepAngleDegrees: 220,
                  clockwise: false,
                ),
              ),
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'sweep-entrance',
                  values: const {
                    'Adopt': 12,
                    'Trial': 24,
                    'Renew': 18,
                    'Advocate': 30,
                  },
                  polarStyle: const PolarColumnStyle(
                    animationMode: PolarColumnAnimationMode.sweep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    PolarColumnSeriesElement element() => tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;

    await tester.pump();
    expect(element().sweepProgress, 0);
    expect(
      List.generate(4, element().isPointRevealedForAnimation),
      everyElement(isFalse),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(element().sweepProgress, closeTo(0.5, 0.02));
    expect(
      List.generate(4, element().isPointRevealedForAnimation),
      orderedEquals([true, true, false, false]),
    );

    await tester.pumpAndSettle();
    expect(element().sweepProgress, 1);
    expect(
      List.generate(4, element().isPointRevealedForAnimation),
      everyElement(isTrue),
    );
    expect(tester.takeException(), isNull);
  });
}
