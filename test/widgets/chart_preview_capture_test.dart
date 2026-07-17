import 'dart:ui' as ui;

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

  testWidgets('pie preview with a positioned legend is fully opaque', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_pieHost(controller));
    await tester.pumpAndSettle();

    final result = await _capture(tester, controller.capturePreview());
    final preview = (result as ChartArtifactSuccess<ChartPreview>).value;
    final isOpaque = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(preview.bytes!);
      final frame = await codec.getNextFrame();
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      var opaque = pixels != null;
      for (var alpha = 3; opaque && alpha < pixels!.lengthInBytes; alpha += 4) {
        opaque = pixels.getUint8(alpha) == 255;
      }
      frame.image.dispose();
      codec.dispose();
      return opaque;
    });

    expect(
      isOpaque,
      isTrue,
      reason: 'Native previews must paint the chart theme background.',
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

Widget _pieHost(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 400,
      height: 300,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: true,
        theme: ChartTheme.vibrant,
        series: [
          PieChartSeries.fromMap(
            id: 'pie',
            name: 'Allocation',
            values: const {'Core': 60, 'Growth': 25, 'Cash': 15},
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
