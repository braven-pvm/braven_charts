// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Widget-level behaviour of [BravenFacetPlot]: N panels, strips, columns.
///
/// The per-panel lowering is proven by the config-parity suite; this file
/// proves the grid mounts one BravenPlot per facet value with the right strips.
library;

import 'package:braven_charts/braven_charts.dart';
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
  testWidgets('renders one BravenPlot per distinct facet value', (tester) async {
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
}
