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
      'generated Source from a spec-built chart formats and analyzes',
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
