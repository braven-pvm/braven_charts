// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

/// One representative faceted chart: 4 panels, fixed scales, strip labels.
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
  Row(t: 0, power: 180, zone: 'A'),
  Row(t: 1, power: 210, zone: 'A'),
  Row(t: 2, power: 240, zone: 'B'),
  Row(t: 3, power: 220, zone: 'B'),
  Row(t: 4, power: 260, zone: 'C'),
  Row(t: 5, power: 300, zone: 'C'),
  Row(t: 6, power: 280, zone: 'D'),
  Row(t: 7, power: 320, zone: 'D'),
];

void main() {
  testWidgets('faceted line, 4 panels, fixed scales', (tester) async {
    tester.view.physicalSize = const Size(720, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('grammar-faceting-golden'),
            child: BravenFacetPlot<Row>(
              const PlotSpec<Row>(
                data: rows,
                marks: <Mark<Row>>[
                  LineMark<Row>(
                    x: rowT,
                    y: rowPower,
                    color: Color(0xFF2563EB),
                  ),
                ],
                facet: FacetSpec<Row>(
                  by: rowZone,
                  columns: 2,
                  label: 'Zone',
                ),
                theme: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('grammar-faceting-golden')),
      matchesGoldenFile('goldens/grammar_faceting_fixed.png'),
    );
  });
}
