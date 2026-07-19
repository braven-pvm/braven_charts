import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'captures, tables, transports, and hydrates Polar Column without shares',
    (tester) async {
      final sourceController = BravenChartController();
      addTearDown(sourceController.dispose);
      const sourceConfig = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -35,
          sweepAngleDegrees: 285,
          clockwise: false,
          innerRadiusFactor: 0.18,
          outerRadiusFactor: 0.91,
          clipMarks: false,
        ),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.2,
          outerPadding: 0.1,
          showLabels: true,
          showGridLines: false,
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: 0,
          maximum: 100,
          scaleMode: PolarRadialScaleMode.areaCorrect,
          tickCount: 6,
          showLabels: false,
          showGridLines: true,
        ),
      );
      final sourceSeries = PolarColumnChartSeries.rose(
        id: 'demand',
        name: 'Demand',
        unit: 'orders',
        color: const Color(0xFF6750A4),
        values: const {'North': 42, 'East': 68, 'South': 31, 'West': 55},
        columnColors: const {'East': Color(0xFF00A878)},
        polarStyle: const PolarColumnStyle(
          cornerRadius: 9,
          opacity: 0.82,
          borderColor: Color(0xFF102030),
          borderWidth: 2,
          showDataLabels: false,
        ),
        selectionStyle: const RadialSelectionStyle(
          effect: RadialSelectionEffect.lift,
          liftScale: 1.12,
          liftOffset: 8,
          backdropBlur: 2,
        ),
      );

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: sourceController,
            polarChartConfig: sourceConfig,
            showLegend: false,
            series: [sourceSeries],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initial = _snapshot(sourceController.extractDocument());
      expect(
        sourceController.selectPoint(
          const ChartPointRef(seriesId: 'demand', pointIndex: 1),
          revision: initial.revision,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pumpAndSettle();

      final snapshot = _snapshot(
        sourceController.extractDocument(
          const ChartDocumentExtractOptions(documentId: 'polar-demand'),
        ),
      );
      expect(snapshot.document.series.single.type, 'polarColumn');
      expect(
        snapshot.document.requiredCapabilities,
        containsAll({'series.polar.column.v1', 'chart.polar.config.v1'}),
      );
      expect(
        snapshot.document.configuration.values['polarChart'],
        isA<JsonObjectValue>(),
      );
      expect(snapshot.viewState?.selectedPointRefs, const [
        ChartPointRef(seriesId: 'demand', pointIndex: 1),
      ]);

      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.projectionKind, ChartTableProjectionKind.polar);
      expect(table.polarRows.map((row) => row.category), [
        'North',
        'East',
        'South',
        'West',
      ]);
      expect(table.polarRows.map((row) => row.valueDisplay), [
        '42.00',
        '68.00',
        '31.00',
        '55.00',
      ]);
      final export = ChartTableExporter.csvForDisplayedRows(
        table,
        polarRows: table.polarRows,
      );
      expect(export.headers, ['#', 'Category', 'Series', 'Value (orders)']);
      expect(export.csv, isNot(contains('Share')));

      final capture = await _capture(
        tester,
        sourceController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'polar-artifact',
            createdAt: DateTime.utc(2026, 7, 19, 12),
            documentOptions: const ChartDocumentExtractOptions(
              documentId: 'polar-demand',
            ),
          ),
        ),
      );
      expect(capture, isA<ChartArtifactSuccess<ChartArtifact>>());
      final artifact = (capture as ChartArtifactSuccess<ChartArtifact>).value;
      final firstJson = _json(ChartArtifactJsonCodec.encode(artifact));
      final secondJson = _json(ChartArtifactJsonCodec.encode(artifact));
      expect(secondJson, firstJson);

      final hydrated = _configuration(
        ChartDocumentHydrator.hydrateJson(firstJson),
      );
      expect(hydrated.polarChartConfig, sourceConfig);
      final restoredSeries = hydrated.series.single as PolarColumnChartSeries;
      expect(restoredSeries.preset, PolarColumnPreset.rose);
      expect(restoredSeries.polarStyle, sourceSeries.polarStyle);
      expect(restoredSeries.selectionStyle, sourceSeries.selectionStyle);
      expect(restoredSeries.categories, sourceSeries.categories);

      final restoredController = BravenChartController();
      addTearDown(restoredController.dispose);
      await tester.pumpWidget(
        _host(hydrated.build(bravenChartController: restoredController)),
      );
      await tester.pumpAndSettle();

      expect(restoredController.selectedPointRefs, {
        const ChartPointRef(seriesId: 'demand', pointIndex: 1),
      });
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 760, height: 620, child: child)),
  ),
);

ChartDocumentSnapshot _snapshot(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

String _json(ChartArtifactResult<String> result) {
  expect(result, isA<ChartArtifactSuccess<String>>());
  return (result as ChartArtifactSuccess<String>).value;
}

HydratedChartConfiguration _configuration(
  ChartArtifactResult<HydratedChartConfiguration> result,
) {
  expect(result, isA<ChartArtifactSuccess<HydratedChartConfiguration>>());
  return (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;
}

Future<ChartArtifactResult<ChartArtifact>> _capture(
  WidgetTester tester,
  Future<ChartArtifactResult<ChartArtifact>> future,
) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump();
  }
  return (await tester.runAsync(
    () => future.timeout(const Duration(seconds: 10)),
  ))!;
}
