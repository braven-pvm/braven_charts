import 'dart:io';
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The release harness intentionally reuses the exact public Gallery widgets.
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/gallery_flagships.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/bar_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/donut_gallery_cards.dart';
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

  testWidgets('capture pub.dev Donut media through the public preview API', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);
    final captures = <_NativeMediaCapture>[];

    for (final source in const [
      (
        label: 'Contribution ring',
        fileName: 'donut_revenue_ring.png',
        widget: RevenueRingGalleryCard(),
        accent: Color(0xFF2563EB),
      ),
      (
        label: 'Partial progress sweep',
        fileName: 'donut_release_progress.png',
        widget: DeliveryProgressGalleryCard(),
        accent: Color(0xFF8B5CF6),
      ),
      (
        label: 'Contribution and reach',
        fileName: 'donut_campaign_reach.png',
        widget: CampaignReachGalleryCard(),
        accent: Color(0xFF0F9F92),
      ),
    ]) {
      final bytes = await _capturePie(
        tester,
        outputDirectory: outputDirectory,
        fileName: source.fileName,
        source: source.widget,
      );
      captures.add(
        _NativeMediaCapture(
          label: source.label,
          bytes: bytes,
          accent: source.accent,
        ),
      );
    }

    await _captureDonutCollection(
      tester,
      outputDirectory: outputDirectory,
      captures: captures,
    );
  });

  testWidgets('capture pub.dev Bar media through the public preview API', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    await _captureInteraction(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'bar_targets_interaction.png',
      source: const BarTargetsGalleryCard(),
    );
  });

  testWidgets(
    'capture pub.dev flagship hero media through the public preview API',
    (tester) async {
      await tester.runAsync(_loadCaptureFont);
      final outputDirectory = Directory(_outputDirectory)
        ..createSync(recursive: true);

      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: 'hero_threshold.png',
        source: const PerformanceIntelligenceGalleryHero(
          panel: PerformanceIntelligenceHeroPanel.sessionProfile,
        ),
      );
      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: 'hero_power_duration.png',
        source: const PerformanceIntelligenceGalleryHero(
          panel: PerformanceIntelligenceHeroPanel.powerDuration,
        ),
      );
    },
  );

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

  testWidgets('capture pub.dev chart type strip', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);
    final captures = <_ChartTypeCapture>[];

    for (final asset in _chartTypeAssets()) {
      captures.add(
        await _captureChartType(
          tester,
          outputDirectory: outputDirectory,
          asset: asset,
        ),
      );
    }

    await _captureChartTypeStrip(
      tester,
      outputDirectory: outputDirectory,
      captures: captures,
    );
  });
}

Future<Uint8List> _capturePie(
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
            annotations: galleryChart.annotations
                .map(_withCaptureAnnotationFont)
                .toList(),
            theme: captureTheme,
            showLegend: galleryChart.showLegend,
            legendStyle: _withCaptureLegendFont(galleryChart.legendStyle),
            grid: galleryChart.grid,
            showXScrollbar: galleryChart.showXScrollbar,
            showYScrollbar: galleryChart.showYScrollbar,
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

  final bytes = preview.bytes!;
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
  // ignore: avoid_print
  print(
    'Wrote ${output.path} (${preview.widthPixels}x${preview.heightPixels})',
  );

  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  return bytes;
}

Future<void> _captureDonutCollection(
  WidgetTester tester, {
  required Directory outputDirectory,
  required List<_NativeMediaCapture> captures,
}) async {
  const logicalSize = Size(1800, 560);
  final boundaryKey = GlobalKey();
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _captureFontFamily),
      home: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: const Color(0xFFF7F5FA),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, capture) in captures.indexed) ...[
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(child: _NativeMediaTile(capture: capture)),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundaryContext = boundaryKey.currentContext!;
  await tester.runAsync(() async {
    for (final capture in captures) {
      await precacheImage(MemoryImage(capture.bytes), boundaryContext);
    }
  });
  await tester.pump();

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final byteData = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data;
  });
  expect(byteData, isNotNull);
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}gallery_donut_collection.png',
  );
  await tester.runAsync(
    () => output.writeAsBytes(byteData!.buffer.asUint8List(), flush: true),
  );
  // ignore: avoid_print
  print('Wrote ${output.path} (1800x560)');
  await tester.pumpWidget(const SizedBox.shrink());
}

class _NativeMediaCapture {
  const _NativeMediaCapture({
    required this.label,
    required this.bytes,
    required this.accent,
  });

  final String label;
  final Uint8List bytes;
  final Color accent;
}

class _NativeMediaTile extends StatelessWidget {
  const _NativeMediaTile({required this.capture});

  final _NativeMediaCapture capture;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              capture.label,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontFamily: _captureFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 72, height: 3, color: capture.accent),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Image.memory(
              capture.bytes,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
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
            legendStyle: _withCaptureLegendFont(galleryChart.legendStyle),
            grid: galleryChart.grid,
            showXScrollbar: galleryChart.showXScrollbar,
            showYScrollbar: galleryChart.showYScrollbar,
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

Future<_ChartTypeCapture> _captureChartType(
  WidgetTester tester, {
  required Directory outputDirectory,
  required _ChartTypeAsset asset,
}) async {
  const logicalSize = Size(360, 260);
  const pixelRatio = 2.0;
  final controller = BravenChartController();
  final theme = _withCaptureFont(asset.theme);
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _captureFontFamily),
      home: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SizedBox.fromSize(
          size: logicalSize,
          child: BravenChartPlus(
            bravenChartController: controller,
            series: asset.series,
            theme: theme,
            showLegend: false,
            grid: asset.grid,
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(position: YAxisPosition.hidden),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));

  final captureFuture = controller.capturePreview(
    const ChartPreviewOptions(pixelRatio: pixelRatio),
  );
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump();
  }
  final result = await tester.runAsync(
    () => captureFuture.timeout(const Duration(seconds: 20)),
  );
  expect(result, isA<ChartArtifactSuccess<ChartPreview>>());
  final preview = (result! as ChartArtifactSuccess<ChartPreview>).value;
  expect(preview.widthPixels, 720);
  expect(preview.heightPixels, 520);
  final bytes = preview.bytes!;
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}${asset.fileName}',
  );
  await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
  // ignore: avoid_print
  print('Wrote ${output.path} (720x520)');

  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  return _ChartTypeCapture(asset: asset, bytes: bytes);
}

Future<void> _captureChartTypeStrip(
  WidgetTester tester, {
  required Directory outputDirectory,
  required List<_ChartTypeCapture> captures,
}) async {
  const logicalSize = Size(2180, 400);
  final boundaryKey = GlobalKey();
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _captureFontFamily),
      home: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: const Color(0xFFF7F5FA),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < captures.length; index++) ...[
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(child: _ChartTypeTile(capture: captures[index])),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundaryContext = boundaryKey.currentContext!;
  await tester.runAsync(() async {
    for (final capture in captures) {
      await precacheImage(MemoryImage(capture.bytes), boundaryContext);
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final byteData = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data;
  });
  expect(byteData, isNotNull);
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}chart_type_strip.png',
  );
  await tester.runAsync(
    () => output.writeAsBytes(byteData!.buffer.asUint8List(), flush: true),
  );
  // ignore: avoid_print
  print('Wrote ${output.path} (2180x400)');
  await tester.pumpWidget(const SizedBox.shrink());
}

class _ChartTypeTile extends StatelessWidget {
  const _ChartTypeTile({required this.capture});

  final _ChartTypeCapture capture;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: capture.asset.theme.backgroundColor,
        border: Border.all(color: const Color(0xFFD8D3E0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: capture.asset.headerColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Text(
                  capture.asset.label,
                  style: TextStyle(
                    color: capture.asset.headerTextColor,
                    fontFamily: _captureFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Image.memory(
                capture.bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTypeAsset {
  const _ChartTypeAsset({
    required this.label,
    required this.fileName,
    required this.series,
    required this.theme,
    required this.headerColor,
    required this.headerTextColor,
    this.grid = const GridConfig(horizontal: true, vertical: false),
  });

  final String label;
  final String fileName;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final Color headerColor;
  final Color headerTextColor;
  final GridConfig grid;
}

class _ChartTypeCapture {
  const _ChartTypeCapture({required this.asset, required this.bytes});

  final _ChartTypeAsset asset;
  final Uint8List bytes;
}

List<_ChartTypeAsset> _chartTypeAssets() {
  final lineTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFF8FBFF),
  );
  final areaTheme = ChartTheme.dark.copyWith(
    backgroundColor: const Color(0xFF101827),
  );
  final scatterTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFFFFBF4),
  );
  final barTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFF5FBF8),
  );
  final pieBase = ChartTheme.light;
  final pieTheme = pieBase.copyWith(
    backgroundColor: const Color(0xFFFFF8FB),
    seriesTheme: pieBase.seriesTheme.copyWith(
      colors: const [
        Color(0xFFE11D48),
        Color(0xFFF97316),
        Color(0xFF8B5CF6),
        Color(0xFF14B8A6),
      ],
    ),
    pieChartTheme: const PieChartTheme(
      cornerRadius: 8,
      borderColorMode: PieBorderColorMode.slice,
      borderLightnessShift: -0.16,
      calloutStyle: LabelStyle(
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        borderWidth: 0,
        borderRadius: 0,
        padding: EdgeInsets.zero,
      ),
    ),
  );
  final donutBase = ChartTheme.dark;
  final donutTheme = donutBase.copyWith(
    backgroundColor: const Color(0xFF101827),
    seriesTheme: donutBase.seriesTheme.copyWith(
      colors: const [
        Color(0xFF38BDF8),
        Color(0xFF22C55E),
        Color(0xFFF59E0B),
        Color(0xFFA78BFA),
      ],
    ),
    pieChartTheme: const PieChartTheme(
      cornerRadius: 8,
      borderColorMode: PieBorderColorMode.slice,
      borderLightnessShift: 0.18,
    ),
  );

  return [
    _ChartTypeAsset(
      label: 'Line',
      fileName: 'chart_type_line.png',
      theme: lineTheme,
      headerColor: const Color(0xFFE7F0FF),
      headerTextColor: const Color(0xFF173B73),
      series: const [
        LineChartSeries(
          id: 'line-primary',
          points: [
            ChartDataPoint(x: 0, y: 18),
            ChartDataPoint(x: 1, y: 27),
            ChartDataPoint(x: 2, y: 23),
            ChartDataPoint(x: 3, y: 39),
            ChartDataPoint(x: 4, y: 44),
            ChartDataPoint(x: 5, y: 38),
            ChartDataPoint(x: 6, y: 56),
            ChartDataPoint(x: 7, y: 62),
          ],
          color: Color(0xFF2563EB),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 3,
          showDataPointMarkers: true,
          dataPointMarkerRadius: 2.5,
        ),
        LineChartSeries(
          id: 'line-secondary',
          points: [
            ChartDataPoint(x: 0, y: 42),
            ChartDataPoint(x: 1, y: 38),
            ChartDataPoint(x: 2, y: 46),
            ChartDataPoint(x: 3, y: 34),
            ChartDataPoint(x: 4, y: 49),
            ChartDataPoint(x: 5, y: 53),
            ChartDataPoint(x: 6, y: 48),
            ChartDataPoint(x: 7, y: 58),
          ],
          color: Color(0xFF06B6D4),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2,
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Area',
      fileName: 'chart_type_area.png',
      theme: areaTheme,
      headerColor: const Color(0xFF1E293B),
      headerTextColor: const Color(0xFFE2E8F0),
      grid: const GridConfig(
        horizontal: true,
        vertical: false,
        horizontalColor: Color(0x2238BDF8),
      ),
      series: const [
        AreaChartSeries(
          id: 'area',
          points: [
            ChartDataPoint(x: 0, y: 26),
            ChartDataPoint(x: 1, y: 38),
            ChartDataPoint(x: 2, y: 31),
            ChartDataPoint(x: 3, y: 49),
            ChartDataPoint(x: 4, y: 42),
            ChartDataPoint(x: 5, y: 57),
            ChartDataPoint(x: 6, y: 51),
            ChartDataPoint(x: 7, y: 68),
          ],
          color: Color(0xFF22D3EE),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
          fillOpacity: 0.24,
          lineGlow: 3,
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Scatter',
      fileName: 'chart_type_scatter.png',
      theme: scatterTheme,
      headerColor: const Color(0xFFFFE8C7),
      headerTextColor: const Color(0xFF7C2D12),
      series: const [
        ScatterChartSeries(
          id: 'scatter-a',
          points: [
            ChartDataPoint(x: 1, y: 16),
            ChartDataPoint(x: 2, y: 28),
            ChartDataPoint(x: 3, y: 24),
            ChartDataPoint(x: 4, y: 42),
            ChartDataPoint(x: 5, y: 37),
            ChartDataPoint(x: 6, y: 54),
            ChartDataPoint(x: 7, y: 49),
          ],
          color: Color(0xFF7C3AED),
          markerRadius: 6,
        ),
        ScatterChartSeries(
          id: 'scatter-b',
          points: [
            ChartDataPoint(x: 1, y: 34),
            ChartDataPoint(x: 2, y: 21),
            ChartDataPoint(x: 3, y: 39),
            ChartDataPoint(x: 4, y: 31),
            ChartDataPoint(x: 5, y: 51),
            ChartDataPoint(x: 6, y: 44),
            ChartDataPoint(x: 7, y: 63),
          ],
          color: Color(0xFFF97316),
          markerRadius: 4.5,
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Bar',
      fileName: 'chart_type_bar.png',
      theme: barTheme,
      headerColor: const Color(0xFFDDF5EA),
      headerTextColor: const Color(0xFF14532D),
      series: const [
        BarChartSeries(
          id: 'bar-plan',
          points: [
            ChartDataPoint(x: 1, y: 32),
            ChartDataPoint(x: 2, y: 46),
            ChartDataPoint(x: 3, y: 39),
            ChartDataPoint(x: 4, y: 58),
            ChartDataPoint(x: 5, y: 52),
          ],
          color: Color(0xFF14B8A6),
          barWidthPercent: 0.72,
        ),
        BarChartSeries(
          id: 'bar-actual',
          points: [
            ChartDataPoint(x: 1, y: 24),
            ChartDataPoint(x: 2, y: 38),
            ChartDataPoint(x: 3, y: 47),
            ChartDataPoint(x: 4, y: 43),
            ChartDataPoint(x: 5, y: 64),
          ],
          color: Color(0xFF2563EB),
          barWidthPercent: 0.72,
          targetValues: [28, 42, 44, 50, 60],
          targetMarkerStyle: BarTargetMarkerStyle(
            color: Color(0xFFF97316),
            width: 1.5,
            lengthFactor: 1.35,
          ),
          errorLowerValues: [19, 32, 41, 37, 57],
          errorUpperValues: [30, 44, 53, 49, 70],
          errorBarStyle: BarErrorBarStyle(
            color: Color(0xFF334155),
            width: 1,
            capLengthFactor: 0.55,
          ),
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Pie',
      fileName: 'chart_type_pie.png',
      theme: pieTheme,
      headerColor: const Color(0xFFFFE4EC),
      headerTextColor: const Color(0xFF831843),
      grid: const GridConfig(horizontal: false, vertical: false),
      series: [
        PieChartSeries.fromMap(
          id: 'pie',
          name: 'Allocation',
          values: const {'Core': 42, 'Growth': 27, 'Income': 18, 'Other': 13},
          pieStyle: const PieChartStyle(
            startAngleDegrees: -90,
            radiusFactor: 0.82,
            sliceGap: 4,
            cornerRadius: 8,
            borderWidth: 1,
            borderColorMode: PieBorderColorMode.slice,
          ),
          dataLabels: const PieDataLabelConfig(
            position: PieDataLabelPosition.inside,
            content: PieDataLabelContent.percentage,
            minimumShare: 0.12,
          ),
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Donut',
      fileName: 'chart_type_donut.png',
      theme: donutTheme,
      headerColor: const Color(0xFFDBEAFE),
      headerTextColor: const Color(0xFF1E3A8A),
      grid: const GridConfig(horizontal: false, vertical: false),
      series: [
        DonutChartSeries.fromMap(
          id: 'donut',
          name: 'Progress',
          values: const {
            'Complete': 46,
            'Review': 24,
            'Active': 18,
            'Queued': 12,
          },
          donutStyle: const DonutChartStyle(
            innerRadiusFactor: 0.58,
            startAngleDegrees: -90,
            radiusFactor: 0.82,
            sliceGap: 3,
            cornerRadius: 8,
            borderWidth: 1,
            borderColorMode: PieBorderColorMode.slice,
          ),
          centerContent: const DonutCenterContent(
            label: 'Total',
            valueMode: DonutCenterValueMode.total,
            labelStyle: LabelStyle(
              textStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              borderRadius: 0,
              padding: EdgeInsets.zero,
            ),
            valueStyle: LabelStyle(
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              borderRadius: 0,
              padding: EdgeInsets.zero,
            ),
          ),
          dataLabels: const PieDataLabelConfig(
            position: PieDataLabelPosition.inside,
            content: PieDataLabelContent.percentage,
            minimumShare: 0.12,
          ),
        ),
      ],
    ),
  ];
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

LegendStyle? _withCaptureLegendFont(LegendStyle? style) {
  if (style == null) return null;
  return style.copyWith(
    textStyle: style.textStyle.copyWith(fontFamily: _captureFontFamily),
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
