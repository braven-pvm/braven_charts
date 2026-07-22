// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Artifact-document parity for the grammar layer.
///
/// PARITY MEANS: mount the same chart twice — once as a [BravenPlot] over a
/// [PlotSpec], once as the hand-written `BravenChartPlus` a user writes today —
/// extract a chart document from each through the ordinary
/// `BravenChartController.extractDocument` path, and assert the two documents
/// are IDENTICAL as JSON. Everything downstream of a document (transport,
/// hydration, tables, Source, AI) therefore cannot tell a spec-built chart from
/// a hand-built one.
///
/// No id normalization is needed: the lowering assigns deterministic
/// `mark-<index>` / `axis-<index>` ids, and the hand-built charts here spell
/// those same ids out. If that ever stops being true, this file goes red — a
/// feature, not a nuisance.
///
/// `test/unit/grammar/plot_lowering_parity_test.dart` is the CONFIG-level
/// sibling of this file.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

List<ChartDataPoint> points(double Function(Row) y) => <ChartDataPoint>[
  for (final row in rows) ChartDataPoint(x: row.t, y: y(row)),
];

/// The axis the lowering synthesizes when a spec declares none.
YAxisConfig defaultAxis() =>
    YAxisConfig(position: YAxisPosition.left).copyWith(id: 'axis-0');

/// Explicit axis slots for the multi-axis shape.
final YAxisConfig wattsAxis = YAxisConfig.withId(
  id: 'watts',
  position: YAxisPosition.left,
  label: 'W',
);
final YAxisConfig bpmAxis = YAxisConfig.withId(
  id: 'bpm',
  position: YAxisPosition.right,
  label: 'bpm',
);

/// Mounts [child] and returns the document its controller extracts.
Future<Map<String, Object?>> documentOf(
  WidgetTester tester,
  Widget Function(BravenChartController controller) child,
) async {
  final controller = BravenChartController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 600, height: 400, child: child(controller)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final result = controller.extractDocument();
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value.document
      .toJson();
}

/// Runs one parity shape: spec-built first, hand-built second, compare.
Future<void> expectArtifactParity(
  WidgetTester tester, {
  required Widget Function(BravenChartController) spec,
  required Widget Function(BravenChartController) handBuilt,
}) async {
  final fromSpec = await documentOf(tester, spec);
  final fromHand = await documentOf(tester, handBuilt);
  expect(fromSpec, fromHand);
}

void main() {
  testWidgets('shape 1: a single line', (tester) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          marks: <Mark<Row>>[
            LineMark<Row>(x: rowT, y: rowPower, name: 'Power'),
          ],
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        series: <ChartSeries>[
          LineChartSeries(
            id: 'mark-0',
            name: 'Power',
            points: points(rowPower),
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
        ],
      ),
    );
  });

  testWidgets('shape 2: multiple series with a trend annotation', (
    tester,
  ) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          marks: <Mark<Row>>[
            LineMark<Row>(
              x: rowT,
              y: rowPower,
              id: 'power',
              name: 'Power',
              color: Color(0xFF2563EB),
            ),
            AreaMark<Row>(
              x: rowT,
              y: rowHeartRate,
              id: 'hr',
              name: 'Heart rate',
              fillOpacity: 0.25,
            ),
            TrendMark<Row>(
              sourceMarkId: 'power',
              id: 'power-trend',
              name: 'Power trend',
              color: Color(0xFFDC2626),
            ),
          ],
          xAxis: XAxisConfig(label: 'Elapsed'),
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        xAxisConfig: const XAxisConfig(label: 'Elapsed'),
        series: <ChartSeries>[
          LineChartSeries(
            id: 'power',
            name: 'Power',
            color: const Color(0xFF2563EB),
            points: points(rowPower),
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
          AreaChartSeries(
            id: 'hr',
            name: 'Heart rate',
            fillOpacity: 0.25,
            points: points(rowHeartRate),
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
        ],
        annotations: <ChartAnnotation>[
          TrendAnnotation(
            id: 'power-trend',
            label: 'Power trend',
            seriesId: 'power',
            trendType: TrendType.linear,
            lineColor: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  });

  testWidgets('shape 3: two marks on two axes', (tester) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        PlotSpec<Row>(
          data: rows,
          marks: const <Mark<Row>>[
            LineMark<Row>(
              x: rowT,
              y: rowPower,
              id: 'power',
              name: 'Power',
              yAxisId: 'watts',
            ),
            LineMark<Row>(
              x: rowT,
              y: rowHeartRate,
              id: 'hr',
              name: 'Heart rate',
              yAxisId: 'bpm',
            ),
          ],
          yAxes: <YAxisConfig>[wattsAxis, bpmAxis],
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        series: <ChartSeries>[
          LineChartSeries(
            id: 'power',
            name: 'Power',
            points: points(rowPower),
            yAxisId: 'watts',
            yAxisConfig: wattsAxis,
          ),
          LineChartSeries(
            id: 'hr',
            name: 'Heart rate',
            points: points(rowHeartRate),
            yAxisId: 'bpm',
            yAxisConfig: bpmAxis,
          ),
        ],
      ),
    );
  });

  testWidgets('shape 4: scatter with every channel', (tester) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          marks: <Mark<Row>>[
            ScatterMark<Row>(
              x: rowT,
              y: rowPower,
              name: 'Efforts',
              size: Channel<Row>(rowEffort, label: 'Effort'),
              colorBy: Channel<Row>(rowHeartRate, label: 'Heart rate'),
              colorEncoding: ScatterColorEncoding(
                colors: <Color>[Color(0xFF16A34A), Color(0xFFDC2626)],
              ),
              opacityBy: Channel<Row>(rowEffort, label: 'Confidence'),
              categoryBy: CategoryChannel<Row>(rowZone, label: 'Zone'),
              categories: <ScatterCategoryStyle>[
                ScatterCategoryStyle(key: 'easy', color: Color(0xFF16A34A)),
                ScatterCategoryStyle(key: 'hard', color: Color(0xFFDC2626)),
              ],
            ),
          ],
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        series: <ChartSeries>[
          ScatterChartSeries(
            id: 'mark-0',
            name: 'Efforts',
            points: <ChartDataPoint>[
              for (final row in rows)
                ChartDataPoint(
                  x: row.t,
                  y: row.power,
                  magnitude: row.effort,
                  colorValue: row.heartRate,
                  opacityValue: row.effort,
                  categoryValue: row.zone,
                ),
            ],
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
            sizeEncoding: const ScatterSizeEncoding(label: 'Effort'),
            colorEncoding: const ScatterColorEncoding(
              colors: <Color>[Color(0xFF16A34A), Color(0xFFDC2626)],
              label: 'Heart rate',
            ),
            opacityEncoding: const ScatterOpacityEncoding(label: 'Confidence'),
            categoryEncoding: const ScatterCategoryEncoding(
              label: 'Zone',
              categories: <ScatterCategoryStyle>[
                ScatterCategoryStyle(key: 'easy', color: Color(0xFF16A34A)),
                ScatterCategoryStyle(key: 'hard', color: Color(0xFFDC2626)),
              ],
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('shape 5: a candlestick', (tester) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          marks: <Mark<Row>>[
            CandlestickMark<Row>(
              x: rowT,
              open: rowOpen,
              high: rowHigh,
              low: rowLow,
              close: rowClose,
              name: 'Price',
            ),
          ],
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        series: <ChartSeries>[
          CandlestickChartSeries(
            id: 'mark-0',
            name: 'Price',
            points: <CandlestickDataPoint>[
              for (final row in rows)
                CandlestickDataPoint(
                  x: row.t,
                  open: row.open,
                  high: row.high,
                  low: row.low,
                  close: row.close,
                ),
            ],
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
        ],
      ),
    );
  });

  testWidgets('shape 7: chart-level grid, title, subtitle and legend', (
    tester,
  ) async {
    // A spec that carries the chart-level options `BravenPlot` forwards must
    // build a document IDENTICAL to the hand-written `BravenChartPlus` that
    // sets the same grid, title, subtitle and legend visibility. This is the
    // document-level proof that PlotSpec's chart-level fields are genuinely
    // forwarded, not dropped.
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          marks: <Mark<Row>>[
            LineMark<Row>(x: rowT, y: rowPower, name: 'Power'),
          ],
          grid: GridConfig(horizontal: false, verticalStrokeWidth: 1.5),
          title: 'Session',
          subtitle: 'Power over time',
          showLegend: false,
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        grid: const GridConfig(horizontal: false, verticalStrokeWidth: 1.5),
        title: 'Session',
        subtitle: 'Power over time',
        showLegend: false,
        series: <ChartSeries>[
          LineChartSeries(
            id: 'mark-0',
            name: 'Power',
            points: points(rowPower),
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
        ],
      ),
    );
  });

  testWidgets('shape 6: transposed bars', (tester) async {
    await expectArtifactParity(
      tester,
      spec: (controller) => BravenPlot<Row>(
        const PlotSpec<Row>(
          data: rows,
          transposed: true,
          marks: <Mark<Row>>[BarMark<Row>(x: rowT, y: rowPower, name: 'Power')],
        ),
        bravenChartController: controller,
      ),
      handBuilt: (controller) => BravenChartPlus(
        bravenChartController: controller,
        series: <ChartSeries>[
          BarChartSeries(
            id: 'mark-0',
            name: 'Power',
            points: points(rowPower),
            barWidthPercent: 0.8,
            orientation: BarOrientation.horizontal,
            yAxisId: 'axis-0',
            yAxisConfig: defaultAxis(),
          ),
        ],
      ),
    );
  });
}
