import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/artifacts/chart_document_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapRasterViewportProviderDescriptor', () {
    test('round-trips portable identity, presentation, and JSON arguments', () {
      final descriptor = _descriptor();

      final decoded = HeatmapRasterViewportProviderDescriptor.fromDocument(
        JsonValue.fromJson(descriptor.toDocument().toJson()) as JsonObjectValue,
      );

      expect(decoded.providerId, 'test.spectrogram-raster.v1');
      expect(decoded.layerId, 'signal-spectrogram');
      expect(decoded.semanticSeriesId, 'spectrogram-resident');
      expect(decoded.initialViewport, _initialViewport);
      expect(decoded.fallback, HeatmapRasterProviderFallback.cell);
      expect(decoded.opacity, 0.85);
      expect(decoded.filterQuality, HeatmapRasterProviderFilterQuality.medium);
      expect(decoded.arguments['recordingId']?.toJson(), 'session-42');
      expect(decoded.arguments['sampleRate']?.toJson(), 48000);
    });

    test('cell fallback requires a canonical semantic series identity', () {
      expect(
        () => HeatmapRasterViewportProviderDescriptor(
          providerId: 'test.spectrogram-raster.v1',
          layerId: 'signal-spectrogram',
          initialViewport: _initialViewport,
          fallback: HeatmapRasterProviderFallback.cell,
        ),
        throwsArgumentError,
      );
    });
  });

  group('portable Heatmap raster viewport provider', () {
    test('extracts one descriptor without embedding raster resources', () {
      final document = _extractRasterDocument().document;

      expect(
        document.requiredCapabilities,
        contains(HeatmapRasterViewportProviderDescriptor.capabilityId),
      );
      final raw =
          document.configuration.values['heatmapRasterViewportProvider']
              as JsonObjectValue;
      expect(raw.toJson(), _descriptor().toDocument().toJson());
      expect(document.interaction.requiredBindings, isEmpty);
      expect(document.series, hasLength(1));
      expect(document.series.single.id, 'spectrogram-resident');
      final json = document.toJson().toString();
      expect(json, isNot(contains('decodedByteCount')));
      expect(json, isNot(contains('imageBytes')));
      expect(json, isNot(contains('dart:ui')));
    });

    test('fails closed when a required provider is unavailable', () {
      final document = _extractRasterDocument(
        descriptor: _descriptor(
          fallback: HeatmapRasterProviderFallback.hardFailure,
        ),
      ).document;

      final result = ChartDocumentHydrator.hydrateDocument(document);

      expect(result, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
      final failure =
          result as ChartArtifactFailure<HydratedChartConfiguration>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(failure.error.message, contains('test.spectrogram-raster.v1'));
    });

    testWidgets('uses canonical cells when the optional provider is absent', (
      tester,
    ) async {
      final result = ChartDocumentHydrator.hydrateDocument(
        _extractRasterDocument().document,
      );
      final configuration =
          (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 320,
              child: configuration.build(),
            ),
          ),
        ),
      );

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      expect(chart.heatmapRasterViewportController, isNull);
      expect(chart.series, hasLength(1));
      expect(chart.series.single.id, 'spectrogram-resident');
    });

    testWidgets(
      'mounts a fresh runtime, forwards viewports, and disposes ownership',
      (tester) async {
        final sources = <_RecordingRasterSource>[];
        final controllers = <HeatmapRasterViewportController>[];
        var factoryCalls = 0;
        final result = ChartDocumentHydrator.hydrateDocument(
          _extractRasterDocument().document,
          runtimeBindings: ChartRuntimeBindings(
            heatmapRasterViewportProviders:
                HeatmapRasterViewportProviderRegistry(
                  factories: {
                    'test.spectrogram-raster.v1': (descriptor, template) {
                      factoryCalls++;
                      expect(template?.id, 'spectrogram-resident');
                      final source = _RecordingRasterSource();
                      final controller = HeatmapRasterViewportController(
                        source: source,
                        semanticDescriptor: HeatmapRasterSemanticDescriptor(
                          seriesId: descriptor.semanticSeriesId!,
                          name: template?.name,
                          unit: template?.unit,
                          colorScale: template!.colorScale,
                        ),
                        maxCachedTiles: 4,
                        maxDecodedBytes: 1024,
                        maxTilesPerViewport: 4,
                      );
                      sources.add(source);
                      controllers.add(controller);
                      return HeatmapRasterViewportProviderRuntime(
                        controller: controller,
                      );
                    },
                  },
                ),
          ),
        );
        final configuration =
            (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 480,
                height: 320,
                child: configuration.build(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(factoryCalls, 1);
        expect(sources.single.requests, isNotEmpty);
        expect(controllers.single.snapshot.mountedViewport, _initialViewport);
        expect(
          controllers.single.snapshot.semanticSeries?.id,
          'spectrogram-resident',
        );
        final chart = tester.widget<BravenChartPlus>(
          find.byType(BravenChartPlus),
        );
        expect(chart.series, isEmpty);
        expect(chart.heatmapRasterViewportController, controllers.single);
        expect(chart.heatmapRasterOpacity, 0.85);

        const nextViewport = HeatmapViewportRequest(
          minimumX: 1,
          maximumX: 4,
          minimumY: 1,
          maximumY: 4,
        );
        chart.interactionConfig!.onViewportChanged!({
          'minX': nextViewport.minimumX,
          'maxX': nextViewport.maximumX,
          'minY': nextViewport.minimumY,
          'maxY': nextViewport.maximumY,
        });
        await tester.pump();
        expect(controllers.single.snapshot.mountedViewport, nextViewport);

        final ownedController = controllers.single;
        await tester.pumpWidget(const SizedBox.shrink());
        await expectLater(
          ownedController.loadViewport(nextViewport),
          throwsStateError,
        );
      },
    );
  });
}

const _initialViewport = HeatmapViewportRequest(
  minimumX: -0.5,
  maximumX: 4.5,
  minimumY: -0.5,
  maximumY: 4.5,
);

HeatmapRasterViewportProviderDescriptor _descriptor({
  HeatmapRasterProviderFallback fallback = HeatmapRasterProviderFallback.cell,
}) => HeatmapRasterViewportProviderDescriptor(
  providerId: 'test.spectrogram-raster.v1',
  layerId: 'signal-spectrogram',
  semanticSeriesId: 'spectrogram-resident',
  initialViewport: _initialViewport,
  fallback: fallback,
  opacity: 0.85,
  filterQuality: HeatmapRasterProviderFilterQuality.medium,
  arguments: {
    'recordingId': const JsonStringValue('session-42'),
    'sampleRate': JsonNumberValue(48000),
  },
);

ChartDocumentSnapshot _extractRasterDocument({
  HeatmapRasterViewportProviderDescriptor? descriptor,
}) {
  final series = HeatmapChartSeries(
    id: 'spectrogram-resident',
    name: 'Signal intensity',
    unit: '%',
    points: [HeatmapDataPoint(x: 0, y: 0, value: 0.4)],
    colorScale: HeatmapColorScale.sequential(
      colors: const [Colors.white, Colors.cyan, Colors.indigo],
    ),
  );
  final theme = ChartTheme.light;
  final result = ChartDocumentExtractor.extract(
    source: ChartDocumentExtractionSource(
      allSeries: [series],
      visibleSeries: [series],
      declaredSeries: [series],
      annotations: const [],
      xAxis: const XAxisConfig(label: 'Sample'),
      axes: [
        YAxisConfig.withId(
          id: 'y',
          label: 'Channel',
          position: YAxisPosition.left,
        ),
      ],
      theme: theme,
      interaction: InteractionConfig(onViewportChanged: (_) {}),
      legendVisible: false,
      legendStyle: theme.legendStyle,
      grid: const GridConfig(),
      normalizationMode: NormalizationMode.none,
      backgroundColor: Colors.white,
      showToolbar: false,
      interactiveAnnotations: true,
      maxAxesPerSide: 3,
      axisSwapMode: AxisSwapMode.sticky,
      viewState: ChartViewState(),
    ),
    options: ChartDocumentExtractOptions(
      documentId: 'portable-raster-provider',
      heatmapRasterViewportProviderDescriptor: descriptor ?? _descriptor(),
    ),
    revision: 1,
  );
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

final class _RecordingRasterSource implements HeatmapRasterTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 5,
    rowCount: 5,
  );

  @override
  int get tileColumnCount => 5;

  @override
  int get tileRowCount => 5;

  final List<HeatmapTileRequest> requests = [];

  @override
  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request) async {
    requests.add(request);
    return HeatmapRasterTile(
      key: request.key,
      bounds: domain.fullBounds,
      resource: _FakeRasterResource(),
      semanticCells: [
        HeatmapDataPoint(
          x: 2,
          y: 2,
          value: 0.5,
          bounds: HeatmapCellBounds(
            xMinimum: domain.fullBounds.minimumX,
            xMaximum: domain.fullBounds.maximumX,
            yMinimum: domain.fullBounds.minimumY,
            yMaximum: domain.fullBounds.maximumY,
          ),
        ),
      ],
    );
  }
}

final class _FakeRasterResource implements HeatmapRasterResource {
  @override
  int get decodedByteCount => 64;

  @override
  void dispose() {}
}
