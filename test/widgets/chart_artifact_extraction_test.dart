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
