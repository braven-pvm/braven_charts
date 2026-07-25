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
import '../example/lib/showcase/widgets/cartesian_release_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/donut_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/pie_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/polar_column_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/range_area_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/scatter_gallery_cards.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/widgets/synchronized_cartesian_gallery_card.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/pages/cartesian_chart_type_pages.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/pages/interaction_page.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/showcase/pages/technical_indicators_page.dart';

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
      fileName: 'pie_revenue_by_product.png',
      source: const SimpleRevenueGalleryCard(),
    );
    await _capturePie(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_revenue_contribution.png',
      source: const RevenueContributionGalleryCard(),
    );
    await _capturePie(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_release_effort.png',
      source: const ReleaseEffortGalleryCard(),
    );
    await _capturePie(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'pie_support_request_mix.png',
      source: const SupportMixGalleryCard(),
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
        label: 'Subscription MRR',
        fileName: 'donut_revenue_ring.png',
        widget: RevenueRingGalleryCard(),
        accent: Color(0xFF2563EB),
        isDark: false,
      ),
      (
        label: 'Release readiness',
        fileName: 'donut_release_progress.png',
        widget: DeliveryProgressGalleryCard(),
        accent: Color(0xFF34D399),
        isDark: true,
      ),
      (
        label: 'Channel efficiency',
        fileName: 'donut_campaign_reach.png',
        widget: CampaignReachGalleryCard(),
        accent: Color(0xFF0F9F92),
        isDark: false,
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
          isDark: source.isDark,
        ),
      );
    }

    await _captureDonutCollection(
      tester,
      outputDirectory: outputDirectory,
      captures: captures,
    );
  });

  testWidgets(
    'capture pub.dev Concentric Donut media through the public preview API',
    (tester) async {
      await tester.runAsync(_loadCaptureFont);
      final outputDirectory = Directory(_outputDirectory)
        ..createSync(recursive: true);

      for (final source in const [
        (
          fileName: 'concentric_revenue_mix.png',
          widget: ConcentricMixGalleryCard(),
        ),
        (
          fileName: 'concentric_service_health.png',
          widget: ConcentricHealthGalleryCard(),
        ),
        (
          fileName: 'concentric_portfolio.png',
          widget: ConcentricPortfolioGalleryCard(),
        ),
      ]) {
        await _capturePie(
          tester,
          outputDirectory: outputDirectory,
          fileName: source.fileName,
          source: source.widget,
        );
      }
    },
  );

  testWidgets(
    'capture pub.dev Polar Column media through the public preview API',
    (tester) async {
      await tester.runAsync(_loadCaptureFont);
      final outputDirectory = Directory(_outputDirectory)
        ..createSync(recursive: true);

      for (final source in const [
        (
          fileName: 'polar_channel_demand.png',
          widget: ChannelMagnitudePolarGalleryCard(),
        ),
        (
          fileName: 'polar_seasonal_rose.png',
          widget: SeasonalRoseGalleryCard(),
        ),
        (
          fileName: 'polar_lifecycle_arc.png',
          widget: LifecycleArcPolarGalleryCard(),
        ),
      ]) {
        await _capturePie(
          tester,
          outputDirectory: outputDirectory,
          fileName: source.fileName,
          source: source.widget,
        );
      }
    },
  );

  testWidgets('capture pub.dev Bar media through the public preview API', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    for (final source in const [
      (
        fileName: 'bar_targets_interaction.png',
        widget: BarTargetsGalleryCard(),
      ),
      (fileName: 'bar_capacity.png', widget: BarCapacityGalleryCard()),
      (fileName: 'bar_waterfall.png', widget: BarWaterfallGalleryCard()),
      (fileName: 'bar_range.png', widget: BarRangeGalleryCard()),
      (fileName: 'bar_horizontal.png', widget: BarHorizontalGalleryCard()),
      (fileName: 'bar_normalized.png', widget: BarNormalizedGalleryCard()),
      (fileName: 'bar_overlay.png', widget: BarOverlayGalleryCard()),
      (fileName: 'bar_rods.png', widget: BarRodsGalleryCard()),
      (fileName: 'bar_gradient.png', widget: BarGradientGalleryCard()),
      (fileName: 'bar_signed.png', widget: BarSignedGalleryCard()),
      (fileName: 'bar_offset.png', widget: BarOffsetGalleryCard()),
      (fileName: 'bar_axes.png', widget: BarAxesGalleryCard()),
      (fileName: 'bar_stacked.png', widget: BarStackedGalleryCard()),
    ]) {
      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: source.fileName,
        source: source.widget,
        includeTransientInteraction:
            source.fileName == 'bar_targets_interaction.png',
      );
    }
  });

  testWidgets('capture pub.dev Scatter media through the public preview API', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    for (final source in const [
      (
        fileName: 'scatter_market_opportunity.png',
        widget: MarketOpportunityScatterCard(),
      ),
      (
        fileName: 'scatter_athlete_readiness.png',
        widget: AthleteReadinessScatterCard(),
      ),
      (
        fileName: 'scatter_equipment_risk.png',
        widget: EquipmentRiskScatterCard(),
      ),
    ]) {
      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: source.fileName,
        source: source.widget,
      );
    }
  });

  testWidgets('capture pub.dev Range Area media', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    for (final source in const [
      (
        fileName: 'range_area_temperature.png',
        widget: TemperatureEnvelopeGalleryCard(),
      ),
      (
        fileName: 'range_area_forecast_fan.png',
        widget: ForecastFanGalleryCard(),
      ),
      (
        fileName: 'range_area_volatility.png',
        widget: VolatilityEnvelopeGalleryCard(),
      ),
    ]) {
      await _captureInteraction(
        tester,
        outputDirectory: outputDirectory,
        fileName: source.fileName,
        source: source.widget,
      );
    }
  });

  testWidgets('capture pub.dev synchronized Cartesian composition', (
    tester,
  ) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);
    await _captureComposition(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'synchronized_route_profile.png',
      source: const SynchronizedCartesianGalleryCard(),
    );
  });

  testWidgets('capture pub.dev 0.10.0 Cartesian media', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    await _captureInteraction(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'candlestick_market_structure.png',
      source: const CandlestickMarketGalleryCard(),
      includeTransientInteraction: false,
    );
    await _captureInteraction(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'value_summary_panel.png',
      source: const ValueSummaryGalleryCard(),
      includeTransientInteraction: false,
    );
  });

  testWidgets('capture pub.dev 0.12.0 Chart Grammar media', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    await _captureComposition(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'grammar_authoring.png',
      source: const _GrammarAuthoringMedia(),
    );
    await _captureComposition(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'grammar_workbench_source.png',
      source: const _GrammarWorkbenchSourceMedia(),
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

  testWidgets('capture pub.dev advanced gallery media', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);

    await _captureInteraction(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'scatter_hexbin_density.png',
      source: const ScatterChartsPage(mediaCapturePreset: 'Hexbin'),
      interactionOffset: const Offset(0.24, 0.52),
    );
    await _captureInteraction(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'scatter_density_contours.png',
      source: const ScatterChartsPage(mediaCapturePreset: 'Density'),
      interactionOffset: const Offset(0.25, 0.5),
    );
    await _captureComposition(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'interaction_navigator.png',
      source: const InteractionPage(mediaCapture: true),
    );
    await _captureComposition(
      tester,
      outputDirectory: outputDirectory,
      fileName: 'technical_indicator_stack.png',
      source: const TechnicalIndicatorsPage(mediaCapture: true),
    );
  });

  testWidgets('capture pub.dev Radial Bar media', (tester) async {
    await tester.runAsync(_loadCaptureFont);
    final outputDirectory = Directory(_outputDirectory)
      ..createSync(recursive: true);
    final primary = _chartTypeAssets().singleWhere(
      (asset) => asset.fileName == 'chart_type_radial_bar.png',
    );

    await _captureChartType(
      tester,
      outputDirectory: outputDirectory,
      asset: primary,
    );
    await _captureChartType(
      tester,
      outputDirectory: outputDirectory,
      asset: _radialBarSignedAsset(),
    );
  });

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
    await _captureFamilyPairs(
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
  const logicalSize = Size(960, 540);
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
            concentricDonutConfig: galleryChart.concentricDonutConfig,
            polarChartConfig: galleryChart.polarChartConfig,
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
  expect(preview.widthPixels, 1920);
  expect(preview.heightPixels, 1080);
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
    this.isDark = false,
  });

  final String label;
  final Uint8List bytes;
  final Color accent;
  final bool isDark;
}

class _NativeMediaTile extends StatelessWidget {
  const _NativeMediaTile({required this.capture});

  final _NativeMediaCapture capture;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = capture.isDark
        ? const Color(0xFF111827)
        : Colors.white;
    final foregroundColor = capture.isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF1F2937);
    final borderColor = capture.isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              capture.label,
              style: TextStyle(
                color: foregroundColor,
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
  bool includeTransientInteraction = true,
  Offset interactionOffset = const Offset(0.54, 0.48),
}) async {
  const logicalSize = Size(1280, 720);
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
      Offset(
        chartBox.size.width * interactionOffset.dx,
        chartBox.size.height * interactionOffset.dy,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));

  final categoryLabels = galleryChart.series.first.points
      .map((point) => point.label ?? point.x.toString())
      .toList(growable: false);
  final xAxisFormatterDescriptor =
      galleryChart.xAxisConfig?.labelFormatter == null
      ? null
      : ChartFormatterDescriptor(
          id: 'braven.pub-media.category-labels',
          arguments: {
            'labels': JsonArrayValue([
              for (final label in categoryLabels) JsonStringValue(label),
            ]),
          },
        ).toDocument();
  final captureFuture = controller.capturePreview(
    ChartPreviewOptions(
      pixelRatio: pixelRatio,
      includeTransientInteractions: includeTransientInteraction,
      documentOptions: ChartDocumentExtractOptions(
        documentId: 'pub-media-$fileName',
        xAxisFormatterDescriptor: xAxisFormatterDescriptor,
      ),
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
  expect(preview.widthPixels, 1920);
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

Future<void> _captureComposition(
  WidgetTester tester, {
  required Directory outputDirectory,
  required String fileName,
  required Widget source,
}) async {
  const logicalSize = Size(1280, 720);
  const pixelRatio = 1.5;
  final boundaryKey = GlobalKey();
  final baseTheme = ThemeData.light();
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: _captureFontFamily,
        textTheme: baseTheme.textTheme.apply(fontFamily: _captureFontFamily),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: _captureFontFamily,
        ),
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox.fromSize(size: logicalSize, child: source),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final byteData = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data;
  });
  expect(byteData, isNotNull);
  final bytes = byteData!.buffer.asUint8List();
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
  // ignore: avoid_print
  print('Wrote ${output.path} (1920x1080)');

  await tester.pumpWidget(const SizedBox.shrink());
}

class _GrammarAuthoringMedia extends StatelessWidget {
  const _GrammarAuthoringMedia();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF8F7FC),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Typed chart grammar',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Describe data, marks, encodings, and references; render through the ordinary Braven Charts pipeline.',
            style: TextStyle(fontSize: 15, color: Color(0xFF625D6B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const ChartCodeBlock(
                      code: _grammarAuthoringCode,
                      wrapLines: true,
                      semanticLabel: 'Typed Braven Chart grammar example',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD9D5E3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      child: _grammarMediaChart().build(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GrammarWorkbenchSourceMedia extends StatelessWidget {
  const _GrammarWorkbenchSourceMedia();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF8F7FC),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Round-trip source from the mounted chart',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'The Workbench emits either effective BravenChartPlus configuration or a fidelity-checked Grammar chain.',
            style: TextStyle(fontSize: 15, color: Color(0xFF625D6B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD9D5E3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BravenChartWorkbench(
                  initialDisplayMode: ChartDisplayMode.source,
                  initialSourceForm: ChartSourceForm.grammar,
                  availableDisplayModes: const {
                    ChartDisplayMode.chart,
                    ChartDisplayMode.data,
                    ChartDisplayMode.split,
                    ChartDisplayMode.source,
                  },
                  grammarSourceOptions: const ChartGrammarSourceOptions(
                    variableName: 'sessionChart',
                    rowClassName: 'SessionSample',
                    rowsVariableName: 'samples',
                  ),
                  chartBuilder: (context, controller) => _grammarMediaChart()
                      .build(bravenChartController: controller),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _grammarAuthoringCode = '''
final chart = BravenChart.of(samples)
    .x((d) => d.minute, label: 'Elapsed (min)')
    .y((d) => d.power, label: 'Power (W)')
    .geomArea(
      name: 'Power',
      color: Color(0xFF2563EB),
      fillOpacity: 0.16,
    )
    .geomLine(
      name: 'Sampled power',
      color: Color(0xFF1D4ED8),
      showDataPointMarkers: true,
    )
    .threshold(
      value: 285,
      color: Color(0xFFDC2626),
    )
    .grid(GridConfig(vertical: false))
    .title('Ride power', subtitle: 'Area, markers and FTP threshold')
    .build();
''';

BravenChart<_GrammarMediaRow> _grammarMediaChart() =>
    BravenChart.of(_grammarMediaRows)
        .x(_grammarMinute, label: 'Elapsed (min)')
        .y(_grammarPower, label: 'Power (W)')
        .geomArea(
          name: 'Power',
          color: const Color(0xFF2563EB),
          fillOpacity: 0.16,
        )
        .geomLine(
          name: 'Sampled power',
          color: const Color(0xFF1D4ED8),
          strokeWidth: 2.4,
          interpolation: LineInterpolation.monotone,
          showDataPointMarkers: true,
        )
        .threshold(
          value: 285,
          color: const Color(0xFFDC2626),
          dashPattern: const <double>[6, 4],
        )
        .grid(const GridConfig(vertical: false))
        .title('Ride power', subtitle: 'Area, markers and FTP threshold')
        .theme(_withCaptureFont(ChartTheme.light));

double _grammarMinute(_GrammarMediaRow row) => row.minute;

double _grammarPower(_GrammarMediaRow row) => row.power;

class _GrammarMediaRow {
  const _GrammarMediaRow(this.minute, this.power);

  final double minute;
  final double power;
}

const _grammarMediaRows = <_GrammarMediaRow>[
  _GrammarMediaRow(0, 168),
  _GrammarMediaRow(5, 186),
  _GrammarMediaRow(10, 204),
  _GrammarMediaRow(15, 232),
  _GrammarMediaRow(20, 258),
  _GrammarMediaRow(25, 276),
  _GrammarMediaRow(30, 292),
  _GrammarMediaRow(35, 306),
  _GrammarMediaRow(40, 298),
  _GrammarMediaRow(45, 314),
  _GrammarMediaRow(50, 322),
  _GrammarMediaRow(55, 307),
  _GrammarMediaRow(60, 336),
];

Future<_ChartTypeCapture> _captureChartType(
  WidgetTester tester, {
  required Directory outputDirectory,
  required _ChartTypeAsset asset,
}) async {
  const logicalSize = Size(480, 270);
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
            concentricDonutConfig: asset.concentricDonutConfig,
            polarChartConfig: asset.polarChartConfig,
            radialBarChartConfig: asset.radialBarChartConfig,
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
  expect(preview.widthPixels, 960);
  expect(preview.heightPixels, 540);
  final bytes = preview.bytes!;
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}${asset.fileName}',
  );
  await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
  // ignore: avoid_print
  print('Wrote ${output.path} (960x540)');

  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  return _ChartTypeCapture(asset: asset, bytes: bytes);
}

Future<void> _captureChartTypeStrip(
  WidgetTester tester, {
  required Directory outputDirectory,
  required List<_ChartTypeCapture> captures,
}) async {
  const logicalSize = Size(2400, 280);
  final boundaryKey = GlobalKey();
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _captureFontFamily),
      home: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: const Color(0xFFF4F2F7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < captures.length; index++) ...[
                  if (index > 0)
                    const SizedBox(
                      width: 1,
                      child: ColoredBox(color: Color(0xFFD8D3E0)),
                    ),
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
  print('Wrote ${output.path} (2400x280)');
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _captureFamilyPairs(
  WidgetTester tester, {
  required Directory outputDirectory,
  required List<_ChartTypeCapture> captures,
}) async {
  final primaryByFile = {
    for (final capture in captures) capture.asset.fileName: capture.bytes,
  };
  const pairs = [
    (
      output: 'family_line_pair.png',
      primary: 'chart_type_line.png',
      secondary: 'synchronized_route_profile.png',
    ),
    (
      output: 'family_area_pair.png',
      primary: 'chart_type_area.png',
      secondary: 'value_summary_panel.png',
    ),
    (
      output: 'family_range_area_pair.png',
      primary: 'chart_type_range_area.png',
      secondary: 'range_area_temperature.png',
    ),
    (
      output: 'family_bar_pair.png',
      primary: 'chart_type_bar.png',
      secondary: 'bar_waterfall.png',
    ),
    (
      output: 'family_scatter_pair.png',
      primary: 'chart_type_scatter.png',
      secondary: 'scatter_market_opportunity.png',
    ),
    (
      output: 'family_candlestick_pair.png',
      primary: 'chart_type_candlestick.png',
      secondary: 'candlestick_market_structure.png',
    ),
    (
      output: 'family_pie_pair.png',
      primary: 'chart_type_pie.png',
      secondary: 'pie_revenue_contribution.png',
    ),
    (
      output: 'family_donut_pair.png',
      primary: 'chart_type_donut.png',
      secondary: 'donut_campaign_reach.png',
    ),
    (
      output: 'family_concentric_donut_pair.png',
      primary: 'chart_type_concentric.png',
      secondary: 'concentric_service_health.png',
    ),
    (
      output: 'family_polar_column_pair.png',
      primary: 'chart_type_polar_column.png',
      secondary: 'polar_lifecycle_arc.png',
    ),
    (
      output: 'family_radial_bar_pair.png',
      primary: 'chart_type_radial_bar.png',
      secondary: 'radial_bar_signed.png',
    ),
  ];

  for (final pair in pairs) {
    final secondaryFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}${pair.secondary}',
    );
    expect(
      secondaryFile.existsSync(),
      isTrue,
      reason: 'Capture ${pair.secondary} before composing family media.',
    );
    await _captureFamilyPair(
      tester,
      outputDirectory: outputDirectory,
      fileName: pair.output,
      primary: primaryByFile[pair.primary]!,
      secondary:
          await tester.runAsync(secondaryFile.readAsBytes) ?? Uint8List(0),
    );
  }
}

Future<void> _captureFamilyPair(
  WidgetTester tester, {
  required Directory outputDirectory,
  required String fileName,
  required Uint8List primary,
  required Uint8List secondary,
}) async {
  const logicalSize = Size(1944, 540);
  final boundaryKey = GlobalKey();
  await tester.binding.setSurfaceSize(logicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: const Color(0xFFF4F2F7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRect(
                  child: Image.memory(
                    primary,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ClipRect(
                  child: Image.memory(
                    secondary,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  final context = boundaryKey.currentContext!;
  if (!context.mounted) {
    throw StateError('Family pair capture detached before rendering.');
  }
  final boundary = context.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(MemoryImage(primary), context),
      precacheImage(MemoryImage(secondary), context),
    ]);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final byteData = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data;
  });
  expect(byteData, isNotNull);
  final output = File(
    '${outputDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await tester.runAsync(
    () => output.writeAsBytes(byteData!.buffer.asUint8List(), flush: true),
  );
  // ignore: avoid_print
  print('Wrote ${output.path} (1944x540)');
  await tester.pumpWidget(const SizedBox.shrink());
}

class _ChartTypeTile extends StatelessWidget {
  const _ChartTypeTile({required this.capture});

  final _ChartTypeCapture capture;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: capture.asset.theme.backgroundColor,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              capture.bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: capture.asset.headerColor.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                  child: Text(
                    capture.asset.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: capture.asset.headerTextColor,
                      fontFamily: _captureFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
    this.concentricDonutConfig = const ConcentricDonutConfig(),
    this.polarChartConfig = const PolarChartConfig(),
    this.radialBarChartConfig = const RadialBarChartConfig(),
  });

  final String label;
  final String fileName;
  final List<ChartSeries> series;
  final ChartTheme theme;
  final Color headerColor;
  final Color headerTextColor;
  final GridConfig grid;
  final ConcentricDonutConfig concentricDonutConfig;
  final PolarChartConfig polarChartConfig;
  final RadialBarChartConfig radialBarChartConfig;
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
  final rangeAreaTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFFAF8FF),
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
  final candlestickTheme = ChartTheme.dark.copyWith(
    backgroundColor: const Color(0xFF101827),
  );
  final concentricTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFFBF8FF),
  );
  final polarTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFF4FAFF),
  );
  final radialBarTheme = ChartTheme.light.copyWith(
    backgroundColor: const Color(0xFFF8FAFF),
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
        LineChartSeries(
          id: 'line-benchmark',
          points: [
            ChartDataPoint(x: 0, y: 31),
            ChartDataPoint(x: 1, y: 33),
            ChartDataPoint(x: 2, y: 35),
            ChartDataPoint(x: 3, y: 38),
            ChartDataPoint(x: 4, y: 41),
            ChartDataPoint(x: 5, y: 45),
            ChartDataPoint(x: 6, y: 50),
            ChartDataPoint(x: 7, y: 54),
          ],
          color: Color(0xFFF59E0B),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 1.6,
          dashPattern: [6, 4],
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
          id: 'area-baseline',
          points: [
            ChartDataPoint(x: 0, y: 18),
            ChartDataPoint(x: 1, y: 29),
            ChartDataPoint(x: 2, y: 24),
            ChartDataPoint(x: 3, y: 36),
            ChartDataPoint(x: 4, y: 31),
            ChartDataPoint(x: 5, y: 44),
            ChartDataPoint(x: 6, y: 41),
            ChartDataPoint(x: 7, y: 50),
          ],
          color: Color(0xFF8B5CF6),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 1.6,
          fillOpacity: 0.14,
          lineGlow: 2,
        ),
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
      label: 'Range Area',
      fileName: 'chart_type_range_area.png',
      theme: rangeAreaTheme,
      headerColor: const Color(0xFFEDE9FE),
      headerTextColor: const Color(0xFF4C1D95),
      series: [
        RangeAreaChartSeries(
          id: 'range-area-outer',
          name: 'Wide interval',
          color: const Color(0xFFC4B5FD),
          interpolation: LineInterpolation.monotone,
          fillOpacity: 0.18,
          points: [
            RangeAreaDataPoint(x: 0, low: 16, high: 35),
            RangeAreaDataPoint(x: 1, low: 19, high: 42),
            RangeAreaDataPoint(x: 2, low: 21, high: 49),
            RangeAreaDataPoint(x: 3, low: 22, high: 56),
            RangeAreaDataPoint(x: 4, low: 26, high: 64),
            RangeAreaDataPoint(x: 5, low: 29, high: 73),
            RangeAreaDataPoint(x: 6, low: 32, high: 82),
            RangeAreaDataPoint(x: 7, low: 36, high: 92),
          ],
        ),
        RangeAreaChartSeries(
          id: 'range-area',
          name: 'Forecast interval',
          color: const Color(0xFF7C3AED),
          interpolation: LineInterpolation.monotone,
          fillOpacity: 0.28,
          upperBoundaryStyle: const RangeAreaBoundaryStyle(
            color: Color(0xFF6D28D9),
            strokeWidth: 2,
          ),
          lowerBoundaryStyle: const RangeAreaBoundaryStyle(
            color: Color(0xFFA78BFA),
            strokeWidth: 1.5,
          ),
          points: [
            RangeAreaDataPoint(x: 0, low: 20, high: 31),
            RangeAreaDataPoint(x: 1, low: 24, high: 37),
            RangeAreaDataPoint(x: 2, low: 27, high: 43),
            RangeAreaDataPoint(x: 3, low: 29, high: 48),
            RangeAreaDataPoint(x: 4, low: 34, high: 55),
            RangeAreaDataPoint(x: 5, low: 38, high: 63),
            RangeAreaDataPoint(x: 6, low: 42, high: 70),
            RangeAreaDataPoint(x: 7, low: 47, high: 78),
          ],
        ),
        const LineChartSeries(
          id: 'range-area-median',
          name: 'Median',
          color: Color(0xFF312E81),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.4,
          points: [
            ChartDataPoint(x: 0, y: 25),
            ChartDataPoint(x: 1, y: 30),
            ChartDataPoint(x: 2, y: 35),
            ChartDataPoint(x: 3, y: 39),
            ChartDataPoint(x: 4, y: 44),
            ChartDataPoint(x: 5, y: 50),
            ChartDataPoint(x: 6, y: 56),
            ChartDataPoint(x: 7, y: 63),
          ],
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
        ScatterChartSeries(
          id: 'scatter-c',
          points: [
            ChartDataPoint(x: 1.4, y: 44),
            ChartDataPoint(x: 2.5, y: 33),
            ChartDataPoint(x: 3.6, y: 48),
            ChartDataPoint(x: 4.7, y: 26),
            ChartDataPoint(x: 5.8, y: 59),
            ChartDataPoint(x: 6.7, y: 35),
          ],
          color: Color(0xFF0EA5E9),
          markerRadius: 3.5,
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
        BarChartSeries(
          id: 'bar-forecast',
          points: [
            ChartDataPoint(x: 1, y: 28),
            ChartDataPoint(x: 2, y: 43),
            ChartDataPoint(x: 3, y: 44),
            ChartDataPoint(x: 4, y: 50),
            ChartDataPoint(x: 5, y: 59),
          ],
          color: Color(0xFFF59E0B),
          barWidthPercent: 0.54,
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Candlestick',
      fileName: 'chart_type_candlestick.png',
      theme: candlestickTheme,
      headerColor: const Color(0xFF1E293B),
      headerTextColor: const Color(0xFFE2E8F0),
      series: [
        CandlestickChartSeries(
          id: 'candlestick',
          points: [
            CandlestickDataPoint(
              x: 0,
              open: 99,
              high: 104,
              low: 97,
              close: 102,
            ),
            CandlestickDataPoint(
              x: 1,
              open: 102,
              high: 108,
              low: 100,
              close: 106,
            ),
            CandlestickDataPoint(
              x: 2,
              open: 106,
              high: 107,
              low: 101,
              close: 104,
            ),
            CandlestickDataPoint(
              x: 3,
              open: 104,
              high: 112,
              low: 103,
              close: 110,
            ),
            CandlestickDataPoint(
              x: 4,
              open: 110,
              high: 116,
              low: 109,
              close: 114,
            ),
            CandlestickDataPoint(
              x: 5,
              open: 114,
              high: 117,
              low: 110,
              close: 112,
            ),
            CandlestickDataPoint(
              x: 6,
              open: 112,
              high: 113,
              low: 106,
              close: 108,
            ),
            CandlestickDataPoint(
              x: 7,
              open: 108,
              high: 116,
              low: 107,
              close: 114,
            ),
            CandlestickDataPoint(
              x: 8,
              open: 114,
              high: 121,
              low: 113,
              close: 119,
            ),
            CandlestickDataPoint(
              x: 9,
              open: 119,
              high: 122,
              low: 115,
              close: 117,
            ),
          ],
          candlestickStyle: const CandlestickChartStyle(
            bodyFillMode: CandlestickBodyFillMode.filled,
            maxBodyWidth: 14,
            bodyWidthFactor: 0.68,
            bodyCornerRadius: 2,
          ),
        ),
        const LineChartSeries(
          id: 'candlestick-average',
          points: [
            ChartDataPoint(x: 3, y: 105.5),
            ChartDataPoint(x: 4, y: 108.5),
            ChartDataPoint(x: 5, y: 110),
            ChartDataPoint(x: 6, y: 111),
            ChartDataPoint(x: 7, y: 112),
            ChartDataPoint(x: 8, y: 112.8),
            ChartDataPoint(x: 9, y: 114.5),
          ],
          color: Color(0xFFFBBF24),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 1.8,
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
    _ChartTypeAsset(
      label: 'Concentric',
      fileName: 'chart_type_concentric.png',
      theme: concentricTheme,
      headerColor: const Color(0xFFEDE9FE),
      headerTextColor: const Color(0xFF5B21B6),
      grid: const GridConfig(horizontal: false, vertical: false),
      concentricDonutConfig: const ConcentricDonutConfig(
        innerRadiusFactor: 0.42,
        outerRadiusFactor: 0.9,
        ringGap: 4,
      ),
      series: [
        DonutChartSeries.fromMap(
          id: 'concentric-outer',
          values: const {'Core': 46, 'Growth': 32, 'Other': 22},
          dataLabels: const PieDataLabelConfig(isVisible: false),
          donutStyle: const DonutChartStyle(sliceGap: 1, cornerRadius: 3),
        ),
        DonutChartSeries.fromMap(
          id: 'concentric-middle',
          values: const {'Core': 31, 'Growth': 44, 'Other': 25},
          dataLabels: const PieDataLabelConfig(isVisible: false),
          donutStyle: const DonutChartStyle(sliceGap: 1, cornerRadius: 3),
        ),
        DonutChartSeries.fromMap(
          id: 'concentric-inner',
          values: const {'Core': 54, 'Growth': 27, 'Other': 19},
          dataLabels: const PieDataLabelConfig(isVisible: false),
          donutStyle: const DonutChartStyle(sliceGap: 1, cornerRadius: 3),
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Polar Column',
      fileName: 'chart_type_polar_column.png',
      theme: polarTheme,
      headerColor: const Color(0xFFE0F2FE),
      headerTextColor: const Color(0xFF075985),
      grid: const GridConfig(horizontal: false, vertical: false),
      polarChartConfig: const PolarChartConfig(
        pane: PolarPaneConfig(outerRadiusFactor: 0.82),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.14,
          showLabels: false,
          showGridLines: false,
        ),
        radialAxis: PolarNumericAxisConfig(
          showLabels: false,
          showGridLines: false,
        ),
      ),
      series: [
        PolarColumnChartSeries.rose(
          id: 'polar',
          values: const {
            'N': 48,
            'NE': 72,
            'E': 58,
            'SE': 86,
            'S': 42,
            'SW': 66,
            'W': 54,
            'NW': 78,
          },
          columnColors: const {
            'N': Color(0xFF0EA5E9),
            'NE': Color(0xFF0891B2),
            'E': Color(0xFF0D9488),
            'SE': Color(0xFF16A34A),
            'S': Color(0xFFF59E0B),
            'SW': Color(0xFFF97316),
            'W': Color(0xFFE11D48),
            'NW': Color(0xFF7C3AED),
          },
          polarStyle: const PolarColumnStyle(
            cornerRadius: 3,
            borderWidth: 0.5,
            showDataLabels: false,
          ),
        ),
      ],
    ),
    _ChartTypeAsset(
      label: 'Radial Bar',
      fileName: 'chart_type_radial_bar.png',
      theme: radialBarTheme,
      headerColor: const Color(0xFFE8E7FF),
      headerTextColor: const Color(0xFF3730A3),
      grid: const GridConfig(horizontal: false, vertical: false),
      radialBarChartConfig: const RadialBarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -90,
          sweepAngleDegrees: 260,
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.88,
        ),
        trackGap: 5,
        showCategoryLabels: false,
        showScaleLabels: false,
        showGridLines: true,
        tickCount: 5,
        thresholds: [RadialBarThreshold(value: 75, color: Color(0xFFEA580C))],
      ),
      series: [
        RadialBarChartSeries.fromMap(
          id: 'radial-bar',
          name: 'Readiness',
          values: const {
            'Build': 92,
            'Quality': 84,
            'Docs': 76,
            'Adoption': 63,
            'Support': 48,
          },
          barColors: const {
            'Build': Color(0xFF2563EB),
            'Quality': Color(0xFF4F46E5),
            'Docs': Color(0xFF7C3AED),
            'Adoption': Color(0xFFDB2777),
            'Support': Color(0xFFF97316),
          },
          radialBarStyle: const RadialBarStyle(
            cornerRadius: 8,
            trackOpacity: 0.1,
            showDataLabels: true,
          ),
        ),
      ],
    ),
  ];
}

_ChartTypeAsset _radialBarSignedAsset() => _ChartTypeAsset(
  label: 'Signed Radial Bar',
  fileName: 'radial_bar_signed.png',
  theme: ChartTheme.dark.copyWith(backgroundColor: const Color(0xFF101827)),
  headerColor: const Color(0xFF1E293B),
  headerTextColor: const Color(0xFFE2E8F0),
  grid: const GridConfig(horizontal: false, vertical: false),
  radialBarChartConfig: const RadialBarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: -90,
      sweepAngleDegrees: 320,
      innerRadiusFactor: 0.2,
      outerRadiusFactor: 0.88,
    ),
    trackGap: 5,
    showCategoryLabels: false,
    showScaleLabels: false,
    showGridLines: true,
    tickCount: 5,
    thresholds: [
      RadialBarThreshold(value: 0, color: Color(0xFFF8FAFC), dashPattern: []),
    ],
  ),
  series: [
    RadialBarChartSeries.fromMap(
      id: 'radial-bar-signed',
      name: 'Change',
      values: const {
        'Search': 42,
        'Social': -18,
        'Email': 31,
        'Referral': -36,
        'Direct': 54,
      },
      minimum: -60,
      maximum: 60,
      baseline: 0,
      barColors: const {
        'Search': Color(0xFF38BDF8),
        'Social': Color(0xFFFB7185),
        'Email': Color(0xFF2DD4BF),
        'Referral': Color(0xFFF97316),
        'Direct': Color(0xFFA78BFA),
      },
      unit: 'pts',
      radialBarStyle: const RadialBarStyle(
        cornerRadius: 8,
        trackOpacity: 0.12,
        showDataLabels: true,
      ),
    ),
  ],
);

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
    // ChartCodeBlock deliberately requests the platform monospace family.
    // Widget tests do not resolve that alias unless we register it explicitly.
    'monospace',
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

  final iconFont = File(
    '${fontDirectory.path}${Platform.pathSeparator}'
    'materialicons-regular.otf',
  );
  if (!iconFont.existsSync()) {
    throw StateError('Flutter Material Icons font not found: ${iconFont.path}');
  }
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(
      iconFont.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  await iconLoader.load();
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
  final valueSummaryTheme = theme.cartesianValueSummaryTheme;
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
    cartesianValueSummaryTheme: valueSummaryTheme.copyWith(
      titleStyle: textStyle(valueSummaryTheme.titleStyle),
      labelStyle: textStyle(valueSummaryTheme.labelStyle),
      valueStyle: textStyle(valueSummaryTheme.valueStyle),
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
    final ErrorBarAnnotation value => value.copyWith(style: style),
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
