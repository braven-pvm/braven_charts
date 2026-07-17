import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The release harness intentionally reuses the exact public Gallery widgets.
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/gallery_flagships.dart';
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

    await _capturePie(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_revenue_contribution.png',
      source: const RevenueContributionGalleryCard(),
    );
    await _capturePie(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_portfolio_allocation.png',
      source: const PortfolioAllocationGalleryCard(),
    );
  });

  testWidgets(
    'capture pub.dev interaction media through the public preview API',
    (tester) async {
      await tester.runAsync(_loadCaptureFont);
      final outputDirectory = Directory(_outputDirectory)
        ..createSync(recursive: true);

      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: 'native_multi_axis_interaction.png',
        source: const PhysiologySessionGalleryCard(),
      );
    },
  );
}

Future<void> _capturePie(
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

Future<void> _captureInteraction(
  WidgetTester tester, {
  required Directory outputDirectory,
  required String fileName,
  required Widget source,
}) async {
  const logicalSize = Size(1200, 720);
  const pixelRatio = 1.5;
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox.fromSize(size: logicalSize, child: source),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
            annotations: galleryChart.annotations
                .map(_withCaptureAnnotationFont)
                .toList(),
            theme: captureTheme,
            showLegend: galleryChart.showLegend,
            legendStyle: galleryChart.legendStyle,
            grid: galleryChart.grid,
            showXScrollbar: galleryChart.showXScrollbar,
            scrollbarTheme: galleryChart.scrollbarTheme,
            normalizationMode: galleryChart.normalizationMode,
            xAxisConfig: galleryChart.xAxisConfig,
            yAxis: galleryChart.yAxis,
            interactionConfig: galleryChart.interactionConfig,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final chartBox = tester.renderObject<RenderBox>(find.byType(BravenChartPlus));
  final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await pointer.addPointer(location: chartBox.localToGlobal(Offset.zero));
  await pointer.moveTo(
    chartBox.localToGlobal(
      Offset(chartBox.size.width * 0.54, chartBox.size.height * 0.48),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));

  final captureFuture = controller.capturePreview(
    const ChartPreviewOptions(
      pixelRatio: pixelRatio,
      includeTransientInteractions: true,
    ),
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
  expect(preview.widthPixels, 1800);
  expect(preview.heightPixels, 1080);
  expect(preview.bytes, isNotEmpty);

  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await tester.runAsync(() => output.writeAsBytes(preview.bytes!, flush: true));
  // ignore: avoid_print
  print(
    'Wrote ${output.path} (${preview.widthPixels}x${preview.heightPixels})',
  );

  await pointer.removePointer();
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
}

Future<void> _loadCaptureFont() async {
  final fontDirectory = _findFlutterMaterialFontDirectory();
  for (final family in const [
    _captureFontFamily,
    // Flutter's test binding maps family-less TextStyles to Ahem. Replace its
    // metrics with Roboto so the release image matches a real Flutter app.
    'Ahem',
    'Roboto',
    'Arial',
    'Helvetica',
  ]) {
    final loader = FontLoader(family);
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
  final axisStyle = theme.axisStyle;
  final interactionTheme = theme.interactionTheme;
  final annotationTheme = theme.annotationTheme;
  TextStyle textStyle(TextStyle style) =>
      style.copyWith(fontFamily: _captureFontFamily);
  LabelStyle labelStyle(LabelStyle style) =>
      style.copyWith(textStyle: textStyle(style.textStyle));
  return theme.copyWith(
    axisStyle: axisStyle.copyWith(
      labelStyle: textStyle(axisStyle.labelStyle),
      titleStyle: textStyle(axisStyle.titleStyle),
    ),
    interactionTheme: interactionTheme.copyWith(
      crosshairLabelStyle: labelStyle(interactionTheme.crosshairLabelStyle),
      tooltipStyle: labelStyle(interactionTheme.tooltipStyle),
    ),
    typographyTheme: theme.typographyTheme.copyWith(
      fontFamily: _captureFontFamily,
    ),
    annotationTheme: annotationTheme.copyWith(
      pointDefaults: annotationTheme.pointDefaults.copyWith(
        labelStyle: labelStyle(annotationTheme.pointDefaults.labelStyle),
      ),
      rangeDefaults: annotationTheme.rangeDefaults.copyWith(
        labelStyle: labelStyle(annotationTheme.rangeDefaults.labelStyle),
      ),
      textDefaults: annotationTheme.textDefaults.copyWith(
        textStyle: textStyle(annotationTheme.textDefaults.textStyle),
      ),
      thresholdDefaults: annotationTheme.thresholdDefaults.copyWith(
        labelStyle: labelStyle(annotationTheme.thresholdDefaults.labelStyle),
      ),
      trendDefaults: annotationTheme.trendDefaults.copyWith(
        labelStyle: labelStyle(annotationTheme.trendDefaults.labelStyle),
      ),
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

ChartAnnotation _withCaptureAnnotationFont(ChartAnnotation annotation) {
  final style = annotation.style.copyWith(
    textStyle: annotation.style.textStyle.copyWith(
      fontFamily: _captureFontFamily,
    ),
  );
  return switch (annotation) {
    final PointAnnotation value => value.copyWith(style: style),
    final RangeAnnotation value => value.copyWith(style: style),
    final TextAnnotation value => value.copyWith(style: style),
    final ThresholdAnnotation value => value.copyWith(style: style),
    final TrendAnnotation value => value.copyWith(style: style),
    final PinAnnotation value => value.copyWith(style: style),
    final ChordAnnotation value => value.copyWith(style: style),
    final LegendAnnotation value => value.copyWith(
      legendStyle: value.legendStyle.copyWith(
        textStyle: value.legendStyle.textStyle.copyWith(
          fontFamily: _captureFontFamily,
        ),
      ),
    ),
  };
}
