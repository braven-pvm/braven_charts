import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/artifacts/chart_document_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapViewportProviderDescriptor', () {
    test('round-trips only portable provider identity and JSON arguments', () {
      final descriptor = _descriptor();

      final decoded = HeatmapViewportProviderDescriptor.fromDocument(
        JsonValue.fromJson(descriptor.toDocument().toJson()) as JsonObjectValue,
      );

      expect(decoded.providerId, 'test.procedural-matrix.v1');
      expect(decoded.seriesId, 'matrix');
      expect(decoded.initialViewport, _initialViewport);
      expect(decoded.arguments['tenant']?.toJson(), 'north');
      expect(decoded.arguments['columnCount']?.toJson(), 100);
    });
  });

  group('portable Heatmap viewport provider', () {
    test('extracts descriptor and suppresses duplicate viewport callback', () {
      final snapshot = _extractProviderDocument();
      final document = snapshot.document;

      expect(
        document.requiredCapabilities,
        contains(HeatmapViewportProviderDescriptor.capabilityId),
      );
      final providers =
          document.configuration.values['heatmapViewportProviders']
              as JsonArrayValue;
      expect(providers.values, hasLength(1));
      expect(
        (providers.values.single as JsonObjectValue).toJson(),
        _descriptor().toDocument().toJson(),
      );
      expect(document.interaction.requiredBindings, isEmpty);
    });

    test('fails closed when the host has not registered the provider', () {
      final result = ChartDocumentHydrator.hydrateDocument(
        _extractProviderDocument().document,
      );

      expect(result, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
      final failure =
          result as ChartArtifactFailure<HydratedChartConfiguration>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(failure.error.message, contains('test.procedural-matrix.v1'));
    });

    testWidgets(
      'hydrates a fresh runtime, loads the initial viewport, forwards changes, '
      'and disposes owned controllers',
      (tester) async {
        final sources = <_RecordingTileSource>[];
        final controllers = <HeatmapViewportController>[];
        final forwardedBounds = <Map<String, double>>[];
        var factoryCalls = 0;
        final result = ChartDocumentHydrator.hydrateDocument(
          _extractProviderDocument().document,
          runtimeBindings: ChartRuntimeBindings(
            heatmapViewportProviders: HeatmapViewportProviderRegistry(
              factories: {
                'test.procedural-matrix.v1': (descriptor, template) {
                  factoryCalls++;
                  final source = _RecordingTileSource();
                  final controller = HeatmapViewportController(
                    source: source,
                    overscanColumns: 0,
                    overscanRows: 0,
                    debounceDuration: Duration.zero,
                  );
                  sources.add(source);
                  controllers.add(controller);
                  return HeatmapViewportProviderRuntime(controller: controller);
                },
              },
            ),
          ),
        );
        final configuration =
            (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;
        // Retain a host notification alongside provider-owned refresh behavior.
        final hydrated = HydratedChartConfiguration(
          series: configuration.series,
          annotations: configuration.annotations,
          xAxis: configuration.xAxis,
          axes: configuration.axes,
          theme: configuration.theme,
          interaction: configuration.interaction.copyWith(
            onViewportChanged: forwardedBounds.add,
          ),
          grid: configuration.grid,
          legendStyle: configuration.legendStyle,
          showLegend: configuration.showLegend,
          showToolbar: configuration.showToolbar,
          interactiveAnnotations: configuration.interactiveAnnotations,
          maxAxesPerSide: configuration.maxAxesPerSide,
          axisSwapMode: configuration.axisSwapMode,
          normalizationMode: configuration.normalizationMode,
          backgroundColor: configuration.backgroundColor,
          runtimeBindings: configuration.runtimeBindings,
          heatmapViewportProviders: configuration.heatmapViewportProviders,
          viewState: configuration.viewState,
          width: 480,
          height: 320,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: hydrated.build())),
          ),
        );
        await tester.pump();

        expect(factoryCalls, 1);
        expect(sources.single.requests, isNotEmpty);
        expect(controllers.single.snapshot.viewport, _initialViewport);
        final rendered = tester.widget<BravenChartPlus>(
          find.byType(BravenChartPlus),
        );
        final nextViewport = const HeatmapViewportRequest(
          minimumX: 20,
          maximumX: 30,
          minimumY: 10,
          maximumY: 20,
        );
        rendered.interactionConfig!.onViewportChanged!({
          'minX': nextViewport.minimumX,
          'maxX': nextViewport.maximumX,
          'minY': nextViewport.minimumY,
          'maxY': nextViewport.maximumY,
        });
        await tester.pump();

        expect(forwardedBounds, hasLength(1));
        expect(controllers.single.snapshot.viewport, nextViewport);

        await tester.tap(find.byType(BravenChartPlus));
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.pump();

        expect(forwardedBounds, hasLength(2));
        expect(forwardedBounds.last, {
          'minX': _initialViewport.minimumX,
          'maxX': _initialViewport.maximumX,
          'minY': _initialViewport.minimumY,
          'maxY': _initialViewport.maximumY,
        });
        expect(controllers.single.snapshot.viewport, _initialViewport);

        final residentSeries =
            tester
                    .widget<BravenChartPlus>(find.byType(BravenChartPlus))
                    .series
                    .single
                as HeatmapChartSeries;
        expect(residentSeries.cells, isNotEmpty);

        sources.single.failNextLoad = true;
        final failedViewport = const HeatmapViewportRequest(
          minimumX: 40,
          maximumX: 50,
          minimumY: 40,
          maximumY: 50,
        );
        rendered.interactionConfig!.onViewportChanged!({
          'minX': failedViewport.minimumX,
          'maxX': failedViewport.maximumX,
          'minY': failedViewport.minimumY,
          'maxY': failedViewport.maximumY,
        });
        await tester.pump();

        expect(controllers.single.snapshot.hasError, isTrue);
        final seriesAfterFailure =
            tester
                    .widget<BravenChartPlus>(find.byType(BravenChartPlus))
                    .series
                    .single
                as HeatmapChartSeries;
        expect(seriesAfterFailure.cells, residentSeries.cells);

        final ownedController = controllers.single;
        await tester.pumpWidget(const SizedBox.shrink());
        expect(
          () => ownedController.requestViewport(nextViewport),
          throwsStateError,
        );
      },
    );
  });
}

const _initialViewport = HeatmapViewportRequest(
  minimumX: 0,
  maximumX: 10,
  minimumY: 0,
  maximumY: 10,
);

HeatmapViewportProviderDescriptor _descriptor() =>
    HeatmapViewportProviderDescriptor(
      providerId: 'test.procedural-matrix.v1',
      seriesId: 'matrix',
      initialViewport: _initialViewport,
      arguments: {
        'tenant': const JsonStringValue('north'),
        'columnCount': JsonNumberValue(100),
      },
    );

ChartDocumentSnapshot _extractProviderDocument() {
  final series = HeatmapChartSeries(
    id: 'matrix',
    points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
    colorScale: HeatmapColorScale.sequential(
      colors: const [Colors.white, Colors.blue],
    ),
  );
  final theme = ChartTheme.light;
  final result = ChartDocumentExtractor.extract(
    source: ChartDocumentExtractionSource(
      allSeries: [series],
      visibleSeries: [series],
      declaredSeries: [series],
      annotations: const [],
      xAxis: const XAxisConfig(label: 'Column'),
      axes: [
        YAxisConfig.withId(id: 'y', label: 'Row', position: YAxisPosition.left),
      ],
      theme: theme,
      interaction: InteractionConfig(onViewportChanged: (_) {}),
      legendVisible: true,
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
      documentId: 'portable-heatmap-provider',
      heatmapViewportProviderDescriptors: {'matrix': _descriptor()},
    ),
    revision: 1,
  );
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

final class _RecordingTileSource implements HeatmapTileSource {
  @override
  final HeatmapMatrixDomain domain = HeatmapMatrixDomain(
    columnCount: 100,
    rowCount: 100,
  );

  @override
  int get tileColumnCount => 10;

  @override
  int get tileRowCount => 10;

  final List<HeatmapTileRequest> requests = [];
  bool failNextLoad = false;

  @override
  Future<HeatmapTile> loadTile(HeatmapTileRequest request) async {
    requests.add(request);
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('Synthetic provider failure');
    }
    return HeatmapTile(
      key: request.key,
      cells: [
        for (var row = request.rowStart; row < request.rowEndExclusive; row++)
          for (
            var column = request.columnStart;
            column < request.columnEndExclusive;
            column++
          )
            HeatmapDataPoint(
              x: column.toDouble(),
              y: row.toDouble(),
              value: (column + row).toDouble(),
            ),
      ],
    );
  }
}
