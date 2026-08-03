import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('extracts an artifact with an exact revision-bound preview', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    final result = await _capture(
      tester,
      controller.extractArtifact(
        ChartArtifactExtractOptions(
          artifactId: 'widget-artifact',
          createdAt: DateTime.utc(2026, 7, 15, 8),
          includePreview: true,
          documentOptions: const ChartDocumentExtractOptions(
            documentId: 'widget-document',
          ),
          previewOptions: const ChartPreviewOptions(pixelRatio: 1.5),
        ),
      ),
    );

    final success = result as ChartArtifactSuccess<ChartArtifact>;
    final artifact = success.value;
    expect(artifact.artifactId, 'widget-artifact');
    expect(artifact.document.documentId, 'widget-document');
    expect(artifact.preview?.bytes, isNotEmpty);
    expect(
      artifact.preview?.documentHash,
      ChartArtifactCanonicalizer.documentHash(artifact.document),
    );
    expect(artifact.renderer.package, 'braven_charts');
    expect(artifact.renderer.version, '0.1.0');
  });

  testWidgets('preview failure returns the native artifact with a warning', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    final result = await _capture(
      tester,
      controller.extractArtifact(
        const ChartArtifactExtractOptions(
          includePreview: true,
          previewOptions: ChartPreviewOptions(maxPixelCount: 1),
        ),
      ),
    );

    final success = result as ChartArtifactSuccess<ChartArtifact>;
    expect(success.value.document.series, hasLength(1));
    expect(success.value.preview, isNull);
    expect(
      success.warnings.map((warning) => warning.code),
      contains(ChartArtifactDiagnosticCodes.previewTooLarge),
    );
  });

  testWidgets(
    'round-trips a pie artifact and recaptures its restored preview',
    (tester) async {
      final sourceController = BravenChartController();
      final restoredController = BravenChartController();
      addTearDown(sourceController.dispose);
      addTearDown(restoredController.dispose);
      await tester.pumpWidget(_pieHost(sourceController));
      await tester.pump();

      final sourceResult = await _capture(
        tester,
        sourceController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'pie-source',
            createdAt: DateTime.utc(2026, 7, 16, 10),
            includePreview: true,
            documentOptions: const ChartDocumentExtractOptions(
              documentId: 'pie-document',
            ),
            previewOptions: const ChartPreviewOptions(pixelRatio: 1),
          ),
        ),
      );
      final source =
          (sourceResult as ChartArtifactSuccess<ChartArtifact>).value;
      expect(source.document.series.single.type, 'pie');
      expect(source.document.requiredCapabilities, {
        'series.pie',
        'series.pie.style.v2',
        'series.pie.corner-treatment.v1',
        'series.radial.data-transitions.v1',
      });
      expect(source.preview?.bytes, isNotEmpty);

      final json =
          (ChartArtifactJsonCodec.encode(source)
                  as ChartArtifactSuccess<String>)
              .value;
      final hydrated =
          (ChartDocumentHydrator.hydrateJson(json)
                  as ChartArtifactSuccess<HydratedChartConfiguration>)
              .value;
      final restoredSeries = hydrated.series.single as PieChartSeries;
      expect(restoredSeries.points.map((point) => point.label), [
        'Subscriptions',
        'Services',
        'Hardware',
      ]);
      expect(restoredSeries.pieStyle.selectionExplodeOffset, 10);

      await tester.pumpWidget(
        _hydratedPieHost(
          hydrated.build(bravenChartController: restoredController),
        ),
      );
      await tester.pump();
      final restoredResult = await _capture(
        tester,
        restoredController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'pie-restored',
            createdAt: DateTime.utc(2026, 7, 16, 10, 1),
            includePreview: true,
            documentOptions: const ChartDocumentExtractOptions(
              documentId: 'pie-restored-document',
            ),
            previewOptions: const ChartPreviewOptions(pixelRatio: 1),
          ),
        ),
      );
      final restored =
          (restoredResult as ChartArtifactSuccess<ChartArtifact>).value;
      expect(restored.preview?.bytes, isNotEmpty);
      expect(
        restored.preview?.documentHash,
        ChartArtifactCanonicalizer.documentHash(restored.document),
      );
      expect(restored.document.series.single.type, 'pie');
    },
  );

  testWidgets('round-trips chart-level and per-series callout policy', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_calloutHost(controller));
    await tester.pump();

    final captured = await _capture(tester, controller.extractArtifact());
    final artifact = (captured as ChartArtifactSuccess<ChartArtifact>).value;
    final json =
        (ChartArtifactJsonCodec.encode(artifact)
                as ChartArtifactSuccess<String>)
            .value;
    final hydrated =
        (ChartDocumentHydrator.hydrateJson(json)
                as ChartArtifactSuccess<HydratedChartConfiguration>)
            .value;

    expect(hydrated.seriesCallouts.enabled, isTrue);
    expect(hydrated.seriesCallouts.side, SeriesCalloutSide.left);
    expect(
      hydrated.seriesCallouts.specFor('power'),
      const SeriesCalloutSpec(
        label: 'Peak power',
        anchor: SeriesCalloutAnchor.maximumVisible,
        priority: 9,
      ),
    );
    expect(hydrated.seriesCallouts.showsSeries('recovery'), isFalse);
  });

  test('detached controller returns chart_not_attached', () async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    final result = await controller.extractArtifact();

    expect(result, isA<ChartArtifactFailure<ChartArtifact>>());
    expect(
      (result as ChartArtifactFailure<ChartArtifact>).error.code,
      ChartArtifactDiagnosticCodes.chartNotAttached,
    );
  });
}

Widget _host(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 320,
      height: 240,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: false,
        series: const [
          LineChartSeries(
            id: 'series',
            points: [ChartDataPoint(x: 1, y: 10), ChartDataPoint(x: 2, y: 20)],
          ),
        ],
      ),
    ),
  ),
);

Widget _pieHost(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 420,
      height: 320,
      child: BravenChartPlus(
        bravenChartController: controller,
        title: 'Revenue mix',
        showLegend: true,
        series: [
          PieChartSeries.fromMap(
            id: 'revenue',
            unit: 'USD',
            values: const {'Subscriptions': 42, 'Services': 31, 'Hardware': 27},
            pieStyle: const PieChartStyle(selectionExplodeOffset: 10),
          ),
        ],
      ),
    ),
  ),
);

Widget _calloutHost(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 520,
      height: 320,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: false,
        seriesCallouts: const SeriesCalloutConfig(
          enabled: true,
          side: SeriesCalloutSide.left,
          series: {
            'power': SeriesCalloutSpec(
              label: 'Peak power',
              anchor: SeriesCalloutAnchor.maximumVisible,
              priority: 9,
            ),
            'recovery': SeriesCalloutSpec(show: false),
          },
        ),
        series: const [
          LineChartSeries(
            id: 'power',
            name: 'Power',
            points: [ChartDataPoint(x: 1, y: 10), ChartDataPoint(x: 2, y: 20)],
          ),
          AreaChartSeries(
            id: 'recovery',
            name: 'Recovery',
            points: [ChartDataPoint(x: 1, y: 8), ChartDataPoint(x: 2, y: 12)],
          ),
        ],
      ),
    ),
  ),
);

Widget _hydratedPieHost(Widget chart) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 420, height: 320, child: chart)),
);

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
