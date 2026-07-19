import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'extracts and hydrates deterministic concentric composition state',
    (tester) async {
      final sourceController = BravenChartController();
      addTearDown(sourceController.dispose);
      const sourceConfig = ConcentricDonutConfig(
        innerRadiusFactor: 0.24,
        outerRadiusFactor: 0.92,
        ringGap: 7,
        order: ConcentricRingOrder.innerToOuter,
        ringWeights: {'current': 2, 'previous': 1},
        legendMode: ConcentricDonutLegendMode.flat,
        centerContent: DonutCenterContent(
          label: 'Portable comparison',
          valueMode: DonutCenterValueMode.custom,
          customValue: '2 periods',
        ),
      );

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: sourceController,
            concentricDonutConfig: sourceConfig,
            showLegend: true,
            theme: ChartTheme.light.copyWith(
              pieChartTheme: const PieChartTheme(
                animationMode: PieAnimationMode.none,
              ),
            ),
            series: _series(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initial = _snapshot(sourceController.extractDocument());
      final selection = sourceController.selectPoint(
        const ChartPointRef(seriesId: 'previous', pointIndex: 1),
        revision: initial.revision,
      );
      expect(selection, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final snapshot = _snapshot(
        sourceController.extractDocument(
          const ChartDocumentExtractOptions(
            documentId: 'concentric-comparison',
          ),
        ),
      );
      expect(
        snapshot.document.requiredCapabilities,
        contains('series.donut.concentric.v1'),
      );
      expect(
        snapshot.document.configuration.values['concentricDonut'],
        isA<JsonObjectValue>(),
      );
      expect(snapshot.viewState?.selectedPointRefs, const [
        ChartPointRef(seriesId: 'previous', pointIndex: 1),
      ]);

      final capture = await _capture(
        tester,
        sourceController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'concentric-artifact',
            createdAt: DateTime.utc(2026, 7, 18, 12),
            includePreview: true,
            documentOptions: const ChartDocumentExtractOptions(
              documentId: 'concentric-comparison',
            ),
            previewOptions: const ChartPreviewOptions(pixelRatio: 1),
          ),
        ),
      );
      expect(capture, isA<ChartArtifactSuccess<ChartArtifact>>());
      final artifact = (capture as ChartArtifactSuccess<ChartArtifact>).value;
      expect(artifact.preview?.bytes, isNotEmpty);
      expect(
        artifact.preview?.documentHash,
        ChartArtifactCanonicalizer.documentHash(artifact.document),
      );
      expect(
        artifact.document.configuration.values['concentricDonut'],
        isA<JsonObjectValue>(),
      );

      final firstJson = _json(ChartArtifactJsonCodec.encode(artifact));
      final secondJson = _json(ChartArtifactJsonCodec.encode(artifact));
      expect(secondJson, firstJson);

      final hydrated = _configuration(
        ChartDocumentHydrator.hydrateJson(firstJson),
      );
      expect(hydrated.concentricDonutConfig, sourceConfig);
      expect(hydrated.series.map((series) => series.id), [
        'current',
        'previous',
      ]);
      expect(
        hydrated.series.map((series) => (series as DonutChartSeries).total),
        [100, 200],
      );
      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.pieRows.map((row) => row.shareDisplay), [
        '60.00%',
        '40.00%',
        '25.00%',
        '75.00%',
      ]);

      final restoredController = BravenChartController();
      addTearDown(restoredController.dispose);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(hydrated.build(bravenChartController: restoredController)),
      );
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel('Donut center, Portable comparison, 2 periods'),
        findsOne,
      );
      expect(restoredController.selectedPointRefs, {
        const ChartPointRef(seriesId: 'previous', pointIndex: 1),
      });
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

List<DonutChartSeries> _series() => [
  DonutChartSeries.fromMap(
    id: 'current',
    name: 'Current period',
    unit: 'USD',
    values: const {'Subscriptions': 60, 'Services': 40},
    centerContent: const DonutCenterContent(
      label: 'Ring-owned center must not win',
    ),
    dataLabels: const PieDataLabelConfig(isVisible: false),
  ),
  DonutChartSeries.fromMap(
    id: 'previous',
    name: 'Previous period',
    unit: 'USD',
    values: const {'Subscriptions': 50, 'Services': 150},
    centerContent: const DonutCenterContent(label: 'Another ring-owned center'),
    dataLabels: const PieDataLabelConfig(isVisible: false),
  ),
];

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
