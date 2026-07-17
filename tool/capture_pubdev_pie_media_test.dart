import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The release harness intentionally reuses the exact public Gallery widgets.
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/pie_gallery_cards.dart';

const _outputDirectory = String.fromEnvironment(
  'PUBDEV_MEDIA_OUTPUT_DIR',
  defaultValue: 'doc/screenshots',
);
const _captureFontFamily = 'BravenPubMediaRoboto';

void main() {
  testWidgets('capture pub.dev Pie media through the public preview API', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    await _capture(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_revenue_contribution.png',
      source: const RevenueContributionGalleryCard(),
    );
    await _capture(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_portfolio_allocation.png',
      source: const PortfolioAllocationGalleryCard(),
    );
  });
}

Future<void> _capture(
  WidgetTester tester, {
  required Directory outputDirectory,
  required String fileName,
  required Widget source,
}) async {
  const logicalSize = Size(600, 440);
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox.fromSize(size: logicalSize, child: source),
      ),
    ),
  );
  await tester.pump();
  final galleryChart = tester.widget<BravenChartPlus>(
    find.byType(BravenChartPlus),
  );
  final captureTheme = _withCaptureFont(galleryChart.theme ?? ChartTheme.light);

  final controller = BravenChartController();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _captureFontFamily),
      home: Scaffold(
        body: SizedBox.fromSize(
          size: logicalSize,
          child: BravenChartPlus(
            bravenChartController: controller,
            series: galleryChart.series,
            theme: captureTheme,
            showLegend: galleryChart.showLegend,
            grid: galleryChart.grid,
            interactionConfig: galleryChart.interactionConfig,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final captureFuture = controller.capturePreview(
    const ChartPreviewOptions(pixelRatio: 2),
  );
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump();
  }
  final result = await tester.runAsync(
    () => captureFuture.timeout(const Duration(seconds: 20)),
  );
  expect(result, isA<ChartArtifactSuccess<ChartPreview>>());
  final preview = (result! as ChartArtifactSuccess<ChartPreview>).value;
  expect(preview.mimeType, 'image/png');
  expect(preview.widthPixels, 1200);
  expect(preview.heightPixels, 880);
  expect(preview.bytes, isNotEmpty);

  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await tester.runAsync(() => output.writeAsBytes(preview.bytes!, flush: true));
  // ignore: avoid_print
  print(
    'Wrote ${output.path} (${preview.widthPixels}x${preview.heightPixels})',
  );

  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
}

Future<void> _loadCaptureFont() async {
  final fontDirectory = _findFlutterMaterialFontDirectory();
  final loader = FontLoader(_captureFontFamily);
  for (final fileName in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final font = File(
      '${fontDirectory.path}${Platform.pathSeparator}$fileName',
    );
    if (!font.existsSync()) {
      throw StateError('Flutter material font not found: ${font.path}');
    }
    loader.addFont(
      font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

Directory _findFlutterMaterialFontDirectory() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final candidate = Directory(
      '${directory.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}material_fonts',
    );
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError(
    'Could not locate Flutter material fonts from '
    '${Platform.resolvedExecutable}.',
  );
}

ChartTheme _withCaptureFont(ChartTheme theme) {
  final calloutStyle = theme.pieChartTheme.calloutStyle;
  return theme.copyWith(
    typographyTheme: theme.typographyTheme.copyWith(
      fontFamily: _captureFontFamily,
    ),
    legendStyle: theme.legendStyle.copyWith(
      textStyle: theme.legendStyle.textStyle.copyWith(
        fontFamily: _captureFontFamily,
      ),
    ),
    pieChartTheme: calloutStyle == null
        ? theme.pieChartTheme
        : theme.pieChartTheme.copyWith(
            calloutStyle: calloutStyle.copyWith(
              textStyle: calloutStyle.textStyle.copyWith(
                fontFamily: _captureFontFamily,
              ),
            ),
          ),
  );
}
