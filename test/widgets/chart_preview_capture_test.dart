import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures a revision-bound PNG at the requested pixel ratio', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    final result = await _capture(
      tester,
      controller.capturePreview(const ChartPreviewOptions(pixelRatio: 2)),
    );
    final success = result as ChartArtifactSuccess<ChartPreview>;
    final preview = success.value;
    final document =
        (controller.extractDocument()
                as ChartArtifactSuccess<ChartDocumentSnapshot>)
            .value
            .document;

    expect(preview.mimeType, 'image/png');
    expect(preview.widthPixels, 640);
    expect(preview.heightPixels, 480);
    expect(preview.pixelRatio, 2);
    expect(preview.byteLength, preview.bytes?.length);
    expect(preview.bytes, isNotEmpty);
    expect(preview.bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(
      preview.documentHash,
      ChartArtifactCanonicalizer.documentHash(document),
    );
  });

  testWidgets('preview failure leaves document extraction usable', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    final preview = await _capture(
      tester,
      controller.capturePreview(const ChartPreviewOptions(maxPixelCount: 1)),
    );

    expect(preview, isA<ChartArtifactFailure<ChartPreview>>());
    expect(
      (preview as ChartArtifactFailure<ChartPreview>).error.code,
      ChartArtifactDiagnosticCodes.previewTooLarge,
    );
    expect(
      controller.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );
  });

  testWidgets('rejects concurrent preview captures with a structured result', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await tester.pump();

    final first = controller.capturePreview();
    final second = await controller.capturePreview();

    expect(second, isA<ChartArtifactFailure<ChartPreview>>());
    expect(
      (second as ChartArtifactFailure<ChartPreview>).error.code,
      ChartArtifactDiagnosticCodes.captureInProgress,
    );
    expect(
      await _capture(tester, first),
      isA<ChartArtifactSuccess<ChartPreview>>(),
    );
  });

  test('detached controller returns chart_not_attached', () async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    final result = await controller.capturePreview();

    expect(result, isA<ChartArtifactFailure<ChartPreview>>());
    expect(
      (result as ChartArtifactFailure<ChartPreview>).error.code,
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

Future<ChartArtifactResult<ChartPreview>> _capture(
  WidgetTester tester,
  Future<ChartArtifactResult<ChartPreview>> future,
) async {
  for (var index = 0; index < 3; index++) {
    await tester.pump();
  }
  return (await tester.runAsync(
    () => future.timeout(const Duration(seconds: 10)),
  ))!;
}
