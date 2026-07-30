// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Widget-level behaviour of [BravenFacetPlot]: N panels, strips, columns.
///
/// The per-panel lowering is proven by the config-parity suite; this file
/// proves the grid mounts one BravenPlot per facet value with the right strips.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row({required this.t, required this.power, required this.zone});
  final double t;
  final double power;
  final Object? zone;
}

double rowT(Row row) => row.t;
double rowPower(Row row) => row.power;
Object? rowZone(Row row) => row.zone;

const rows = <Row>[
  Row(t: 0, power: 180, zone: 'easy'),
  Row(t: 1, power: 260, zone: 'hard'),
  Row(t: 2, power: 220, zone: 'easy'),
  Row(t: 3, power: 300, zone: 'max'),
];

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 800, height: 600, child: child)),
  ),
);

void main() {
  testWidgets('renders one BravenPlot per distinct facet value', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BravenPlot<Row>), findsNWidgets(3));
  });

  testWidgets('strip labels are the facet values, prefixed by label', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone, label: 'Zone'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zone: easy'), findsOneWidget);
    expect(find.text('Zone: hard'), findsOneWidget);
    expect(find.text('Zone: max'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit columns override is respected', (tester) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone, columns: 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3 panels, 3 columns → a single grid row of 3 panels.
    expect(find.byType(BravenPlot<Row>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the panel cap surfaces as a diagnostic from build', (
    tester,
  ) async {
    final many = <Row>[
      for (var i = 0; i < 51; i++) Row(t: i.toDouble(), power: 1, zone: 'z$i'),
    ];
    await tester.pumpWidget(
      host(
        BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: many,
            marks: const <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: const FacetSpec<Row>(by: rowZone),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<GrammarSpecException>().having(
        (e) => e.code,
        'code',
        GrammarDiagnosticCode.facetPanelCapExceeded,
      ),
    );
  });

  testWidgets('a non-positive columns count surfaces as a diagnostic, not a '
      'hang', (tester) async {
    // Finding 1: columns <= 0 would never advance the panel-layout loop and
    // hang the UI thread. The guard must throw during build so this COMPLETES.
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone, columns: 0),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<GrammarSpecException>().having(
        (e) => e.code,
        'code',
        GrammarDiagnosticCode.facetColumnsNotPositive,
      ),
    );
  });

  group('synchronized interaction', () {
    List<BravenPlot<Row>> panelPlots(WidgetTester tester) => tester
        .widgetList<BravenPlot<Row>>(find.byType(BravenPlot<Row>))
        .toList();

    testWidgets('fixed scales wire every panel to ONE shared controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controllers = panelPlots(
        tester,
      ).map((p) => p.interactionGroupController).toSet();
      expect(controllers, hasLength(1));
      expect(controllers.single, isNotNull);
    });

    testWidgets('freeX / free leave the panels independent (no controller)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone, scales: FacetScales.free),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        panelPlots(tester).every((p) => p.interactionGroupController == null),
        isTrue,
      );
    });

    testWidgets('a crosshair-x driven on one panel reflects on the shared '
        'controller', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone),
              interaction: InteractionConfig(
                crosshair: CrosshairConfig(
                  displayMode: CrosshairDisplayMode.tracking,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = panelPlots(tester).first.interactionGroupController!;
      final renderFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      );
      final renderBox = tester.firstRenderObject<ChartRenderBox>(renderFinder);
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
      await pointer.moveTo(tester.getTopLeft(renderFinder.first) + local);
      await tester.pump();

      expect(controller.cursorX, closeTo(dataX, 0.0001));
    });
  });

  group('panel mount', () {
    testWidgets('a facet panel keeps the multi-axis mount', (tester) async {
      // A facet panel's spec is exactly the shape the legacy single-axis mount
      // in `braven_plot.dart` claims — one declared (or synthesized) axis, no
      // mark naming it — so without a gate it would be re-mounted with a
      // widget-level `yAxis` and unbound series.
      //
      // It must NOT be. The two mounts do not render the same chart: the
      // widget-level axis honours `min`/`max` while an inline `yAxisConfig`
      // does not, so re-mounting a panel changes what every faceted chart
      // draws — measured at 11.94% of the `grammar_faceting_fixed` golden.
      // That difference is a SEPARATE defect (`FacetScales.fixed` never
      // reaching the render through the multi-axis path) and fixing it is not
      // this seam's job, so the seam is gated off inside a panel and the
      // faceted render is left exactly as it was.
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final charts = tester
          .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
          .toList();
      expect(charts, hasLength(3));
      for (final chart in charts) {
        expect(chart.yAxis, isNull);
        expect(chart.series.single.yAxisId, isNotNull);
        // The shared range `FacetScales.fixed` injects still reaches the chart
        // the only way it ever has — through the inline axis config.
        expect(chart.series.single.yAxisConfig?.min, 180);
        expect(chart.series.single.yAxisConfig?.max, 300);
      }
    });

    testWidgets('a plain BravenPlot of the SAME spec still mounts the legacy '
        'shape — the gate is the panel, not the spec', (tester) async {
      // The control for the test above: identical single-axis spec, mounted
      // outside a facet grid, keeps the legacy mount this slice introduced.
      // Without this, "facet panels keep the multi-axis mount" could be
      // satisfied by the seam being broken everywhere.
      await tester.pumpWidget(
        host(
          BravenPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: const <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              yAxes: <YAxisConfig>[
                YAxisConfig.withId(
                  id: 'y',
                  position: YAxisPosition.left,
                  min: 180,
                  max: 300,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      // Mounted, and mounted ANONYMOUSLY: `'y'` is the id extraction stamps on
      // a widget-level axis that carried none, so the mount unwinds it and the
      // axis reaches the render under the same effective id a config chart's
      // would. See `_asAuthoredWidgetAxis` in `braven_plot.dart` — including
      // why that is now an identity claim and not an appearance one. What this
      // control cares
      // about is unchanged — the widget-level axis is SET here and null in a
      // panel — and the min/max it carries is asserted below, because that is
      // the difference the panel gate exists to protect.
      expect(chart.yAxis, isNotNull);
      expect(chart.yAxis?.id, '');
      expect(chart.yAxis?.min, 180);
      expect(chart.yAxis?.max, 300);
      expect(chart.series.single.yAxisId, isNull);
      expect(chart.series.single.yAxisConfig, isNull);
    });
  });
}
