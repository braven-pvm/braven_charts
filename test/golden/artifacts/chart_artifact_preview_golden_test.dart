import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _previewSize = Size(720, 420);

void main() {
  final variants = <String, ChartTheme>{
    'light': ChartTheme.light,
    'dark': ChartTheme.dark,
    'high_contrast': ChartTheme.highContrast,
  };

  for (final variant in variants.entries) {
    testWidgets('artifact preview golden stays stable for ${variant.key}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = _previewSize;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _chartHost(controller, _pinnedTheme(variant.value)),
      );
      await tester.pump();
      controller.selectSeries('power');
      await tester.pump();
      // Headless tests do not have a display raster loop. Prime the composed
      // chart layer once before exercising the production preview boundary.
      final paintedSource = await tester.runAsync(
        () => captureImage(tester.element(find.byType(BravenChartPlus))),
      );
      paintedSource!.dispose();

      final result = await _completeCapture(
        tester,
        controller.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'preview-${variant.key}',
            createdAt: DateTime.utc(2026, 7, 15, 12),
            includePreview: true,
            documentOptions: ChartDocumentExtractOptions(
              documentId: 'preview-${variant.key}-document',
              includeViewState: true,
            ),
            previewOptions: const ChartPreviewOptions(pixelRatio: 1),
          ),
        ),
      );
      final success = result as ChartArtifactSuccess<ChartArtifact>;
      final artifact = success.value;
      final preview = artifact.preview!;

      expect(preview.widthPixels, _previewSize.width);
      expect(preview.heightPixels, _previewSize.height);
      expect(preview.pixelRatio, 1);
      expect(
        preview.documentHash,
        ChartArtifactCanonicalizer.documentHash(artifact.document),
      );
      expect(artifact.viewState?.selectedSeriesId, 'power');

      await tester.runAsync<void>(
        () => expectLater(
          preview.bytes!,
          matchesGoldenFile('goldens/artifact_preview_${variant.key}.png'),
        ),
      );
    });
  }
}

ChartTheme _pinnedTheme(ChartTheme source) => source.copyWith(
  typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
  animationTheme: source.animationTheme.copyWith(
    dataUpdateDuration: Duration.zero,
    themeChangeDuration: Duration.zero,
    interactionDuration: Duration.zero,
  ),
);

Widget _chartHost(BravenChartController controller, ChartTheme theme) =>
    MaterialApp(
      locale: const Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Ahem'),
      builder: (context, child) => MediaQuery.withNoTextScaling(child: child!),
      home: Scaffold(
        body: SizedBox.fromSize(
          size: _previewSize,
          child: BravenChartPlus(
            bravenChartController: controller,
            theme: theme,
            title: 'Aerobic power and cardiac response comparison',
            subtitle: 'Pinned artifact preview - interval session 2026-07-15',
            showLegend: true,
            xAxisConfig: const XAxisConfig(
              label: 'Elapsed interval sample',
              min: 0,
              max: 7,
              tickCount: 4,
            ),
            annotations: [
              ThresholdAnnotation(
                id: 'sustainable-power-threshold',
                axis: AnnotationAxis.y,
                value: 260,
                label: 'Sustainable power threshold 260 W',
                lineColor: const Color(0xFFF59E0B),
                lineWidth: 2,
              ),
            ],
            series: [
              LineChartSeries(
                id: 'power',
                name: 'Power output - left axis',
                unit: 'W',
                color: const Color(0xFF2563EB),
                isXOrdered: true,
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Mechanical power output',
                  unit: 'watts',
                  min: 180,
                  max: 340,
                  tickCount: 5,
                ),
                points: const [
                  ChartDataPoint(x: 0, y: 205),
                  ChartDataPoint(x: 1, y: 238),
                  ChartDataPoint(x: 2, y: 276),
                  ChartDataPoint(x: 3, y: 315),
                  ChartDataPoint(x: 4, y: 287),
                  ChartDataPoint(x: 5, y: 264),
                  ChartDataPoint(x: 6, y: 244),
                  ChartDataPoint(x: 7, y: 222),
                ],
              ),
              LineChartSeries(
                id: 'heart-rate',
                name: 'Heart rate response - right axis',
                unit: 'bpm',
                color: const Color(0xFFDC2626),
                isXOrdered: true,
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.right,
                  label: 'Cardiac response',
                  unit: 'beats per minute',
                  min: 110,
                  max: 180,
                  tickCount: 5,
                ),
                points: const [
                  ChartDataPoint(x: 0, y: 118),
                  ChartDataPoint(x: 1, y: 127),
                  ChartDataPoint(x: 2, y: 139),
                  ChartDataPoint(x: 3, y: 153),
                  ChartDataPoint(x: 4, y: 162),
                  ChartDataPoint(x: 5, y: 167),
                  ChartDataPoint(x: 6, y: 164),
                  ChartDataPoint(x: 7, y: 158),
                ],
              ),
            ],
          ),
        ),
      ),
    );

Future<ChartArtifactResult<ChartArtifact>> _completeCapture(
  WidgetTester tester,
  Future<ChartArtifactResult<ChartArtifact>> future,
) async {
  for (var index = 0; index < 3; index++) {
    await tester.pump();
  }
  return (await tester.runAsync(
    () => future.timeout(const Duration(seconds: 10)),
  ))!;
}
