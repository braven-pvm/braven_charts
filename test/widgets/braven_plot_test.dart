// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Widget-level behaviour of [BravenPlot].
///
/// The lowering itself is proven by `test/unit/grammar/plot_lowering_parity_test.dart`
/// and the artifact round-trip by `braven_plot_artifact_parity_test.dart`. This
/// file proves the WIDGET: that every mark family reaches the render box, that
/// the controllers a host needs are wired through, that the multi-axis path is
/// the one taken, and that the empty-data contract holds.
library;

import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/widgets/chart_state_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/generated_source_compile.dart';

class Row {
  const Row({
    required this.t,
    required this.power,
    required this.heartRate,
    required this.effort,
    required this.zone,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final double t;
  final double power;
  final double heartRate;
  final double effort;
  final String zone;
  final double open;
  final double high;
  final double low;
  final double close;
}

double rowT(Row row) => row.t;
double rowPower(Row row) => row.power;
double rowHeartRate(Row row) => row.heartRate;
double rowEffort(Row row) => row.effort;
Object rowZone(Row row) => row.zone;
double rowOpen(Row row) => row.open;
double rowHigh(Row row) => row.high;
double rowLow(Row row) => row.low;
double rowClose(Row row) => row.close;

const rows = <Row>[
  Row(
    t: 0,
    power: 180,
    heartRate: 120,
    effort: 1,
    zone: 'easy',
    open: 10,
    high: 14,
    low: 9,
    close: 12,
  ),
  Row(
    t: 1,
    power: 220,
    heartRate: 140,
    effort: 4,
    zone: 'hard',
    open: 12,
    high: 16,
    low: 11,
    close: 15,
  ),
  Row(
    t: 2,
    power: 260,
    heartRate: 165,
    effort: 9,
    zone: 'easy',
    open: 15,
    high: 18,
    low: 13,
    close: 14,
  ),
];

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 600, height: 400, child: child)),
  ),
);

ChartRenderBox renderBoxOf(WidgetTester tester) =>
    tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );

Iterable<SeriesElement> seriesElements(WidgetTester tester) =>
    renderBoxOf(tester).debugElements.whereType<SeriesElement>();

/// The raw RGBA of [chart] rendered at the fixed [host] size.
///
/// Used to compare two MOUNTS of the same chart. A golden cannot do this job:
/// every grammar golden runs at a 3.5% cross-platform antialiasing tolerance,
/// and the difference between the mounts is a gutter-sized recolour well under
/// it. Two images produced in the same test at the same size are exactly
/// comparable, so equality is asserted on the bytes.
Future<Uint8List> _renderBytes(
  WidgetTester tester,
  String probe,
  Widget chart,
) async {
  final key = ValueKey<String>(probe);
  await tester.pumpWidget(host(RepaintBoundary(key: key, child: chart)));
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  // `toImage` is REAL async — it never completes inside a widget test's
  // fake-async zone — so it has to run through `runAsync`, the same escape
  // hatch `matchesGoldenFile` uses.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

void main() {
  group('every mark family pumps and paints', () {
    testWidgets('line', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final series = seriesElements(tester).toList();
      expect(series, hasLength(1));
      expect(series.single.series, isA<LineChartSeries>());
      expect(series.single.series.id, 'mark-0');
    });

    testWidgets('area', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[AreaMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(seriesElements(tester).single.series, isA<AreaChartSeries>());
    });

    testWidgets('bar', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[BarMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(seriesElements(tester).single.series, isA<BarChartSeries>());
    });

    testWidgets('transposed bar takes the horizontal orientation', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              transposed: true,
              marks: <Mark<Row>>[BarMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final series = seriesElements(tester).single.series as BarChartSeries;
      expect(series.orientation, BarOrientation.horizontal);
    });

    testWidgets('scatter with every channel', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[
                ScatterMark<Row>(
                  x: rowT,
                  y: rowPower,
                  size: Channel<Row>(rowEffort, label: 'Effort'),
                  colorBy: Channel<Row>(rowHeartRate, label: 'HR'),
                  colorEncoding: ScatterColorEncoding(
                    colors: <Color>[Color(0xFF16A34A), Color(0xFFDC2626)],
                  ),
                  opacityBy: Channel<Row>(rowEffort),
                  categoryBy: CategoryChannel<Row>(rowZone, label: 'Zone'),
                  categories: <ScatterCategoryStyle>[
                    ScatterCategoryStyle(key: 'easy', color: Color(0xFF16A34A)),
                    ScatterCategoryStyle(key: 'hard', color: Color(0xFFDC2626)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final series = seriesElements(tester).single.series as ScatterChartSeries;
      expect(series.sizeEncoding?.label, 'Effort');
      expect(series.colorEncoding?.label, 'HR');
      // opacityBy carries no label, so the ramp is the package default.
      expect(series.opacityEncoding, const ScatterOpacityEncoding());
      expect(series.categoryEncoding?.label, 'Zone');
      expect(series.points.first.magnitude, 1);
      expect(series.points.first.categoryValue, 'easy');
    });

    testWidgets('candlestick', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[
                CandlestickMark<Row>(
                  x: rowT,
                  open: rowOpen,
                  high: rowHigh,
                  low: rowLow,
                  close: rowClose,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        seriesElements(tester).single.series,
        isA<CandlestickChartSeries>(),
      );
    });

    testWidgets('trend lowers to an annotation element beside its source', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[
                LineMark<Row>(x: rowT, y: rowPower, id: 'power'),
                TrendMark<Row>(sourceMarkId: 'power'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(seriesElements(tester), hasLength(1));
      expect(
        renderBoxOf(tester).debugElements.whereType<TrendAnnotationElement>(),
        hasLength(1),
      );
    });
  });

  group('multi-axis path', () {
    testWidgets('two marks on two axes reach the chart as two axes', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: const <Mark<Row>>[
                LineMark<Row>(x: rowT, y: rowPower, yAxisId: 'power'),
                LineMark<Row>(x: rowT, y: rowHeartRate, yAxisId: 'hr'),
              ],
              yAxes: <YAxisConfig>[
                YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
                YAxisConfig.withId(id: 'hr', position: YAxisPosition.right),
              ],
            ),
            bravenChartController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final snapshot = success(controller.extractDocument());
      expect(snapshot.document.axes.map((axis) => axis.id), <String>[
        'power',
        'hr',
      ]);
      // Both series carry their axis binding, which is what selects the
      // multi-axis path over the legacy single-axis one.
      expect(snapshot.document.series.map((series) => series.axisId), <String>[
        'power',
        'hr',
      ]);
    });
  });

  group('legacy single-axis mount', () {
    testWidgets('a single-axis chain mounts the legacy shape', (tester) async {
      // The chain declares one axis and no mark binds explicitly, so BravenPlot
      // should mount it the way a config author would — widget-level yAxis,
      // series unbound — otherwise the emitted chain produces a DIFFERENT
      // document from the chart it was reversed from.
      final chart = BravenChart.of(rows)
          .x(rowT)
          .yAxis(YAxisConfig.withId(id: 'y', position: YAxisPosition.left))
          .geomLine(y: rowPower)
          .build();
      await tester.pumpWidget(host(chart));
      await tester.pumpAndSettle();

      final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      // ANONYMOUS, not `'y'`. `'y'` is the id extraction stamps on a
      // widget-level axis that carried none, so a chain reversed from a config
      // chart always spells it, and unwinding it mounts the axis under the
      // same effective id the config chart's gets (`'primary_axis'`). The
      // DOCUMENT still says `'y'`: the next test asserts it.
      //
      // This is an identity claim, not an appearance one. It USED to be both —
      // an axis mounted under any id no series was bound to lost its tint —
      // but that was the dangling-binding defect in
      // `MultiAxisManager.getEffectiveBindings`, and with it fixed both mounts
      // draw the same picture.
      expect(plus.yAxis, isNotNull);
      expect(plus.yAxis?.id, '');
      expect(plus.series.single.yAxisId, isNull);
      expect(plus.series.single.yAxisConfig, isNull);
    });

    testWidgets('an axis the author NAMED keeps its name at the mount', (
      tester,
    ) async {
      // The other half of `_asAuthoredWidgetAxis`: only the `'y'` fallback is
      // unwound. A named axis survives extraction as its own id, and the config
      // chart it reverses to is written with that same name, so the mount must
      // not anonymise it.
      final chart = BravenChart.of(rows)
          .x(rowT)
          .yAxis(YAxisConfig.withId(id: 'watts', position: YAxisPosition.left))
          .geomLine(y: rowPower)
          .build();
      await tester.pumpWidget(host(chart));
      await tester.pumpAndSettle();

      final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      expect(plus.yAxis?.id, 'watts');
      expect(plus.series.single.yAxisId, isNull);
      expect(plus.series.single.yAxisConfig, isNull);
    });

    testWidgets('the mounted document carries the legacy axis shape', (
      tester,
    ) async {
      // The document is what the round-trip proof compares, so assert the
      // legacy shape where it actually matters: one axis, no per-series
      // axisId, no inlineAxis.
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      final chart = BravenChart.of(rows)
          .x(rowT)
          .yAxis(
            YAxisConfig.withId(
              id: 'y',
              position: YAxisPosition.left,
              label: 'Power',
            ),
          )
          .geomLine(y: rowPower, id: 'power')
          .build(bravenChartController: controller);
      await tester.pumpWidget(host(chart));
      await tester.pumpAndSettle();

      final snapshot = success(controller.extractDocument());
      expect(snapshot.document.axes.map((axis) => axis.id), <String>['y']);
      expect(snapshot.document.series.single.axisId, isNull);
      expect(snapshot.document.series.single.inlineAxis, isNull);
    });

    testWidgets('a multi-axis chain still binds per series', (tester) async {
      // Two declared axes, each carrying an EXPLICIT per-mark binding. This is
      // the control: the legacy mount must not touch it.
      final chart = BravenChart.of(rows)
          .x(rowT)
          .yAxis(YAxisConfig.withId(id: 'left', position: YAxisPosition.left))
          .yAxis(YAxisConfig.withId(id: 'right', position: YAxisPosition.right))
          .geomLine(y: rowPower, yAxisId: 'left')
          .geomLine(y: rowHeartRate, yAxisId: 'right')
          .build();
      await tester.pumpWidget(host(chart));
      await tester.pumpAndSettle();

      final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      expect(plus.yAxis, isNull);
      expect(plus.series.map((series) => series.yAxisId), <String>[
        'left',
        'right',
      ]);
      expect(plus.series.map((series) => series.yAxisConfig?.id), <String>[
        'left',
        'right',
      ]);
    });

    testWidgets('a single-axis chain renders the SAME pixels as the config '
        'chart it reverses to', (tester) async {
      // The mount change is not document-only: it changes what a chain-built
      // single-axis chart DRAWS, and this is the contract that replaces the old
      // appearance. `AxisColorResolver` tints an axis from the first series
      // BOUND to it (`y_axis_config.dart`: "If null, uses the color of the
      // first bound series"), and the legacy chart's series ARE bound at the
      // render level — `MultiAxisManager.getEffectiveBindings` sends a series
      // carrying no binding of its own to the chart's primary axis — so the Y
      // tick and axis labels take the series colour, and the chain has to do
      // the same.
      //
      // What makes that true is the BINDING, not the id the axis is mounted
      // under. It used to be both: `getEffectiveBindings` hardcoded the
      // synthetic `'primary_axis'`, which exists only when the widget-level
      // axis is anonymous, so mounting the `'y'` fallback verbatim left the
      // axis dangling and grey. That was the dangling-binding defect; the fix
      // is in `MultiAxisManager`, and the mount now agrees with the config
      // chart under either id. `_asAuthoredWidgetAxis` still unwinds the
      // fallback — see its doc for what it is still worth — but this test no
      // longer depends on it.
      //
      // The config twin is written with the ordinary `YAxisConfig(...)`
      // constructor DELIBERATELY: that constructor takes no id, so it is what
      // every config author actually writes, and it is the chart whose
      // extraction produces the `id: 'y'` the chain below carries.
      //
      // Nothing else pinned this. The grammar goldens are exactly this shape
      // and they tolerate 3.5%, while the recolour is confined to the Y-label
      // gutter and measures ~1.4%, so it passed straight through them.
      // `braven_plot_pixel_parity_test.dart` carries the wider shape census.
      final chain = await _renderBytes(
        tester,
        'chain',
        BravenChart.of(rows)
            .x(rowT)
            .yAxis(YAxisConfig.withId(id: 'y', position: YAxisPosition.left))
            .geomLine(y: rowPower, id: 'power', color: const Color(0xFF2563EB))
            .build(),
      );
      final config = await _renderBytes(
        tester,
        'config',
        BravenChartPlus(
          yAxis: YAxisConfig(position: YAxisPosition.left),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 180),
                ChartDataPoint(x: 1, y: 220),
                ChartDataPoint(x: 2, y: 260),
              ],
              color: Color(0xFF2563EB),
            ),
          ],
        ),
      );
      expect(chain, config);

      // The control, and the reason the assertion above is not vacuous: an
      // axis with NOTHING bound to it draws a DIFFERENT chart, and a raw byte
      // comparison sees it. Same axis, same series, but the series names an
      // axis this chart does not have, so `AxisColorResolver` finds no bound
      // series and the Y tick and axis labels drop from the series colour to
      // its `#333333` default. Measured at 4,658 of 240,000 pixels, all in the
      // Y-label gutter, in `braven_plot_pixel_parity_test.dart`.
      //
      // Two earlier controls stopped discriminating and neither may come back.
      // The inline `yAxisConfig` mount: with no min/max on the axis the two
      // mounts genuinely agree pixel for pixel (they still diverge on an axis
      // that carries min/max, which is the control in the pixel-parity file).
      // And the `id: 'y'` widget-level mount: it differed only because of the
      // dangling-binding defect, which is now fixed — a control may not assert
      // a defect, so it is replaced by this one, which reaches the same grey
      // through a binding that is genuinely dangling.
      final danglingBinding = await _renderBytes(
        tester,
        'dangling-binding',
        BravenChartPlus(
          yAxis: YAxisConfig(position: YAxisPosition.left),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 180),
                ChartDataPoint(x: 1, y: 220),
                ChartDataPoint(x: 2, y: 260),
              ],
              color: Color(0xFF2563EB),
              yAxisId: 'an-axis-this-chart-does-not-have',
            ),
          ],
        ),
      );
      expect(danglingBinding, isNot(chain));
    });

    testWidgets('one axis with an EXPLICIT binding is not the legacy shape', (
      tester,
    ) async {
      // Guards the second half of the gate on its own. One axis is declared,
      // but the mark names it, so the author asked for the multi-axis path and
      // must keep getting it.
      final chart = BravenChart.of(rows)
          .x(rowT)
          .yAxis(YAxisConfig.withId(id: 'y', position: YAxisPosition.left))
          .geomLine(y: rowPower, yAxisId: 'y')
          .build();
      await tester.pumpWidget(host(chart));
      await tester.pumpAndSettle();

      final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      expect(plus.yAxis, isNull);
      expect(plus.series.single.yAxisId, 'y');
      expect(plus.series.single.yAxisConfig?.id, 'y');
    });
  });

  group('controller pass-through', () {
    testWidgets('bravenChartController drives and observes the plot', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          BravenPlot<Row>(
            const PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[
                LineMark<Row>(x: rowT, y: rowPower, id: 'power'),
                LineMark<Row>(x: rowT, y: rowHeartRate, id: 'hr'),
              ],
            ),
            bravenChartController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(seriesElements(tester), hasLength(2));

      controller.setSeriesVisible('hr', false);
      await tester.pumpAndSettle();

      expect(controller.hiddenSeriesIds, <String>{'hr'});
      expect(seriesElements(tester), hasLength(1));
    });

    testWidgets('interactionGroupController joins the plot to a group', (
      tester,
    ) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);

      await tester.pumpWidget(
        host(
          BravenPlot<Row>(
            const PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              // Also proves PlotSpec.interaction reaches the widget: without
              // tracking crosshair the plot publishes no cursor at all.
              interaction: InteractionConfig(
                crosshair: CrosshairConfig(
                  displayMode: CrosshairDisplayMode.tracking,
                ),
              ),
            ),
            interactionGroupController: group,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      );
      final renderBox = renderBoxOf(tester);
      const dataX = 1.0;
      final local = renderBox.plotToWidget(
        renderBox.transform!.dataToPlot(
          dataX,
          (renderBox.transform!.dataYMin + renderBox.transform!.dataYMax) / 2,
        ),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getTopLeft(renderFinder) + local);
      await tester.pump();

      expect(group.cursorX, closeTo(dataX, 0.0001));
    });
  });

  group('empty data renders the package empty state', () {
    // DECISION: an empty data list is a runtime STATE (a filter cleared, a
    // fetch returned nothing), not an authoring error, so BravenPlot catches
    // exactly GrammarDiagnosticCode.emptyData and hands the chart an empty
    // series list — which is how every other entry point in this package
    // reaches ChartEmptyStateView. Every other diagnostic still surfaces.
    testWidgets('no rows shows the empty state instead of throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChartEmptyStateView), findsOneWidget);
    });

    testWidgets('the empty-state configuration is honored', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            ),
            emptyStateConfig: ChartEmptyStateConfig(title: 'No rides yet'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No rides yet'), findsOneWidget);
    });

    testWidgets('a spec-level PolarChartConfig survives the empty-data path', (
      tester,
    ) async {
      // `PlotSpec.polar` is a spec FIELD, so it is data-independent exactly
      // like grid/title/subtitle/showLegend — and BravenPlot's own comment says
      // chart-level options must reach the chart even when `lowered` is null.
      // Reading it off `lowered` alone dropped it on the one path where
      // `lowered` is always null, so the empty state (and the very next build,
      // if it hot-swapped) lost the author's pane and radial-axis settings.
      const polar = PolarChartConfig(
        pane: PolarPaneConfig(startAngleDegrees: -45, innerRadiusFactor: 0.15),
        radialAxis: PolarNumericAxisConfig(tickCount: 7),
      );
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[
                PolarMark<Row>(id: 'load', category: rowZone, value: rowPower),
              ],
              polar: polar,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChartEmptyStateView), findsOneWidget);
      final delivered = tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .polarChartConfig;
      // The field read first, because PolarChartConfig has no toString: a whole
      // -object mismatch otherwise reports "Instance of 'PolarChartConfig'"
      // against itself.
      expect(delivered.pane.startAngleDegrees, -45);
      expect(delivered.radialAxis.tickCount, 7);
      expect(delivered, polar);
    });

    testWidgets('a Cartesian spec still hands the chart the default polar '
        'config', (tester) async {
      // The other half: `PlotSpec.polar` on a non-polar spec is refused above
      // the empty-data guard, so carrying it can never leak a config onto a
      // Cartesian chart — this pins that the fallback stays the const default.
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<BravenChartPlus>(find.byType(BravenChartPlus))
            .polarChartConfig,
        const PolarChartConfig(),
      );
    });

    testWidgets('an authoring error still surfaces with no rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(data: <Row>[], marks: <Mark<Row>>[]),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<GrammarSpecException>().having(
          (error) => error.code,
          'code',
          GrammarDiagnosticCode.emptyMarks,
        ),
      );
    });

    testWidgets('a typo\'d trend source still surfaces with no rows', (
      tester,
    ) async {
      // The doc-comment promises "an unknown trend source" still surfaces from
      // build even with no rows. A structural error must not hide behind the
      // empty-state path until real data arrives.
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[
                LineMark<Row>(x: rowT, y: rowPower, id: 'power'),
                TrendMark<Row>(sourceMarkId: 'typo'),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<GrammarSpecException>().having(
          (error) => error.code,
          'code',
          GrammarDiagnosticCode.unknownTrendSource,
        ),
      );
    });

    testWidgets('a channel without its encoding still surfaces with no rows', (
      tester,
    ) async {
      // The doc-comment promises "a channel without its encoding" still
      // surfaces from build even with no rows.
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: <Row>[],
              marks: <Mark<Row>>[
                ScatterMark<Row>(
                  x: rowT,
                  y: rowPower,
                  colorBy: Channel<Row>(rowHeartRate),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<GrammarSpecException>().having(
          (error) => error.code,
          'code',
          GrammarDiagnosticCode.missingChannelEncoding,
        ),
      );
    });

    testWidgets('a spec diagnostic surfaces from the widget build', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[TrendMark<Row>(sourceMarkId: 'nope')],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<GrammarSpecException>().having(
          (error) => error.code,
          'code',
          GrammarDiagnosticCode.unknownTrendSource,
        ),
      );
    });
  });

  group('workbench and generated source accept a spec-built chart', () {
    testWidgets('Chart / Data / Split / Source round-trip', (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                height: 560,
                child: BravenChartWorkbench(
                  chartController: chartController,
                  workbenchController: workbenchController,
                  // The default test surface is 800px wide; the workbench only
                  // offers Split below its breakpoint.
                  splitBreakpoint: 600,
                  availableDisplayModes: const <ChartDisplayMode>{
                    ChartDisplayMode.chart,
                    ChartDisplayMode.data,
                    ChartDisplayMode.split,
                    ChartDisplayMode.source,
                  },
                  chartBuilder: (context, controller) => BravenPlot<Row>(
                    const PlotSpec<Row>(
                      data: rows,
                      marks: <Mark<Row>>[
                        LineMark<Row>(x: rowT, y: rowPower, id: 'power'),
                        TrendMark<Row>(sourceMarkId: 'power'),
                      ],
                    ),
                    bravenChartController: controller,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        chartController.extractDocument(),
        isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
      );

      workbenchController.setDisplayMode(ChartDisplayMode.data);
      await tester.pumpAndSettle();
      expect(workbenchController.tableModel?.rowCount, rows.length);

      workbenchController.setDisplayMode(ChartDisplayMode.split);
      await tester.pumpAndSettle();
      expect(workbenchController.effectiveMode, ChartDisplayMode.split);

      workbenchController.setDisplayMode(ChartDisplayMode.source);
      await tester.pumpAndSettle();
      expect(
        workbenchController.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      expect(
        workbenchController.sourceState.generated?.source,
        contains('LineChartSeries'),
      );

      workbenchController.setDisplayMode(ChartDisplayMode.chart);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(seriesElements(tester), hasLength(1));
    });

    testWidgets(
      'generated Source from a spec-built chart parses and analyzes',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          host(
            BravenPlot<Row>(
              const PlotSpec<Row>(
                data: rows,
                marks: <Mark<Row>>[
                  LineMark<Row>(x: rowT, y: rowPower, id: 'power'),
                  ScatterMark<Row>(
                    x: rowT,
                    y: rowHeartRate,
                    id: 'hr',
                    size: Channel<Row>(rowEffort, label: 'Effort'),
                  ),
                ],
                xAxis: XAxisConfig(label: 'Elapsed'),
              ),
              bravenChartController: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final snapshot = success(controller.extractDocument());
        final generated =
            (ChartDartSourceGenerator.generate(snapshot)
                    as ChartArtifactSuccess<ChartGeneratedSource>)
                .value;

        // The point of the proof: nothing grammar-shaped survives into the
        // emitted Dart — a spec-built chart emits ordinary config.
        expect(generated.source, contains('LineChartSeries'));
        expect(generated.source, contains('ScatterChartSeries'));
        expect(generated.source, isNot(contains('PlotSpec')));
        expect(generated.source, isNot(contains('BravenPlot')));
        expect(generated.source, isNot(contains('LineMark')));

        // runAsync: the compile proof shells out to `dart format`/`dart
        // analyze`, which cannot complete under the widget tester's fake async.
        await tester.runAsync(
          () => expectGeneratedSourceCompiles(
            generated.source,
            fixtureName: 'braven_plot_generated_source_compile_test',
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

ChartDocumentSnapshot success(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) => (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
