import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'rehydrates effective data, durable view state, and interaction',
    (tester) async {
      final sourceController = BravenChartController();
      final hydratedController = BravenChartController();
      addTearDown(sourceController.dispose);
      addTearDown(hydratedController.dispose);

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: sourceController,
            annotations: [
              ThresholdAnnotation(
                id: 'threshold',
                axis: AnnotationAxis.y,
                value: 15,
              ),
            ],
            series: const [
              LineChartSeries(
                id: 'series',
                name: 'Series',
                points: [
                  ChartDataPoint(x: 1, y: 10),
                  ChartDataPoint(x: 2, y: 20),
                ],
              ),
              LineChartSeries(
                id: 'hidden',
                name: 'Hidden',
                points: [
                  ChartDataPoint(x: 1, y: 12),
                  ChartDataPoint(x: 2, y: 18),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      sourceController.setSeriesVisible('hidden', false);
      await tester.pump();
      final source = _success(sourceController.extractDocument()).value;
      final restoredViewState = ChartViewState(
        visibleBounds: const ChartBoundsDocument(
          xMin: 1.25,
          xMax: 1.75,
          yMin: 11,
          yMax: 19,
        ),
        hiddenSeriesIds: const {'hidden'},
        selectedPointRefs: const [
          ChartPointRef(seriesId: 'series', pointIndex: 1),
        ],
      );

      var selected = 0;
      final hydration = _success(
        ChartDocumentHydrator.hydrateDocument(
          source.document,
          viewState: restoredViewState,
          runtimeBindings: ChartRuntimeBindings(
            onSeriesSelected: (_) => selected++,
          ),
        ),
      );
      await tester.pumpWidget(
        _host(hydration.value.build(bravenChartController: hydratedController)),
      );
      await tester.pump();
      await tester.pump();

      final hydrated = _success(hydratedController.extractDocument()).value;
      hydratedController.selectSeries('series');

      expect(hydrated.document.pointCount, source.document.pointCount);
      expect(hydrated.document.annotations.single.id, 'threshold');
      expect(hydrated.viewState?.hiddenSeriesIds, {'hidden'});
      expect(hydrated.viewState?.visibleBounds?.xMin, 1.25);
      expect(hydrated.viewState?.visibleBounds?.xMax, 1.75);
      expect(hydratedController.selectedPointRefs, {
        const ChartPointRef(seriesId: 'series', pointIndex: 1),
      });
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rebinds an extracted inline Y-axis formatter descriptor', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final descriptor = ChartFormatterDescriptor(
      id: 'braven.number.fixed',
      arguments: {'decimals': JsonNumberValue(1)},
    ).toDocument();

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          series: [
            LineChartSeries(
              id: 'formatted',
              points: const [ChartDataPoint(x: 1, y: 12.34)],
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.left,
                labelFormatter: (value) => value.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final extracted = _success(
      controller.extractDocument(
        ChartDocumentExtractOptions(
          yAxisFormatterDescriptors: {'formatted_axis': descriptor},
        ),
      ),
    ).value;
    final hydrated = _success(
      ChartDocumentHydrator.hydrateDocument(extracted.document),
    ).value;

    expect(
      hydrated.series.single.yAxisConfig?.labelFormatter?.call(12.34),
      '12.3',
    );
  });

  test('each hydration and widget build receives fresh runtime identity', () {
    final document = _portableDocument();
    final first = _success(
      ChartDocumentHydrator.hydrateDocument(document),
    ).value;
    final second = _success(
      ChartDocumentHydrator.hydrateDocument(document),
    ).value;

    expect(identical(first.series, second.series), isFalse);
    expect(identical(first.series.single, second.series.single), isFalse);
  });

  test('applies captured, adaptive, override, and reference-only themes', () {
    final capturedTheme = ChartTheme.vibrant;
    final hostTheme = ChartTheme.dark;
    final capturedDocument = _portableDocument(theme: capturedTheme);

    final asCaptured = _success(
      ChartDocumentHydrator.hydrateDocument(
        capturedDocument,
        options: ChartHydrationOptions(hostTheme: hostTheme),
      ),
    );
    final adaptiveWithoutHost = _success(
      ChartDocumentHydrator.hydrateDocument(
        capturedDocument,
        options: const ChartHydrationOptions(
          themeMode: ChartThemeHydrationMode.adaptToHost,
        ),
      ),
    );
    final adaptiveWithHost = _success(
      ChartDocumentHydrator.hydrateDocument(
        capturedDocument,
        options: ChartHydrationOptions(
          themeMode: ChartThemeHydrationMode.adaptToHost,
          hostTheme: hostTheme,
        ),
      ),
    );
    final override = _success(
      ChartDocumentHydrator.hydrateDocument(
        capturedDocument,
        options: ChartHydrationOptions(
          themeMode: ChartThemeHydrationMode.hostOverride,
          hostTheme: hostTheme,
        ),
      ),
    );

    expect(
      _themeFingerprint(asCaptured.value.theme),
      _themeFingerprint(capturedTheme),
    );
    expect(
      _themeFingerprint(adaptiveWithoutHost.value.theme),
      _themeFingerprint(capturedTheme),
    );
    expect(identical(adaptiveWithHost.value.theme, hostTheme), isTrue);
    expect(identical(override.value.theme, hostTheme), isTrue);

    final referenceOnly = _portableDocument(
      themeDocument: _success(
        ChartThemeDocumentCodec.encode(
          capturedTheme,
          captureMode: ChartThemeCaptureMode.referenceOnly,
          reference: 'showcase.vibrant',
        ),
      ).value,
    );
    final referenceFailure = ChartDocumentHydrator.hydrateDocument(
      referenceOnly,
    );
    final referenceWithHost = _success(
      ChartDocumentHydrator.hydrateDocument(
        referenceOnly,
        options: ChartHydrationOptions(
          themeMode: ChartThemeHydrationMode.adaptToHost,
          hostTheme: hostTheme,
        ),
      ),
    );
    final missingOverride = ChartDocumentHydrator.hydrateDocument(
      capturedDocument,
      options: const ChartHydrationOptions(
        themeMode: ChartThemeHydrationMode.hostOverride,
      ),
    );

    expect(
      (referenceFailure as ChartArtifactFailure<HydratedChartConfiguration>)
          .error
          .code,
      ChartArtifactDiagnosticCodes.runtimeBindingRequired,
    );
    expect(identical(referenceWithHost.value.theme, hostTheme), isTrue);
    expect(
      (missingOverride as ChartArtifactFailure<HydratedChartConfiguration>)
          .error
          .code,
      ChartArtifactDiagnosticCodes.runtimeBindingRequired,
    );
  });

  testWidgets('renders safely when a captured font family is unavailable', (
    tester,
  ) async {
    final missingFontTheme = ChartTheme.light.copyWith(
      typographyTheme: ChartTheme.light.typographyTheme.copyWith(
        fontFamily: 'BravenDefinitelyMissingFont',
      ),
    );
    final configuration = _success(
      ChartDocumentHydrator.hydrateDocument(
        _portableDocument(theme: missingFontTheme),
      ),
    ).value;

    expect(
      configuration.theme.typographyTheme.fontFamily,
      'BravenDefinitelyMissingFont',
    );

    await tester.pumpWidget(_host(configuration.build()));
    await tester.pump();

    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forwards every host interaction binding to the restored chart', (
    tester,
  ) async {
    ChartDataPoint? tappedPoint;
    String? tappedSeries;
    ChartDataPoint? hoveredPoint;
    String? hoveredSeries;
    Offset? backgroundPosition;
    String? selectedSeries;
    ChartAnnotation? tappedAnnotation;
    ChartAnnotation? draggedAnnotation;
    Offset? draggedPosition;
    String? deselectedSeries;
    final bindings = ChartRuntimeBindings(
      onPointTap: (point, seriesId) {
        tappedPoint = point;
        tappedSeries = seriesId;
      },
      onPointHover: (point, seriesId) {
        hoveredPoint = point;
        hoveredSeries = seriesId;
      },
      onBackgroundTap: (position) => backgroundPosition = position,
      onSeriesSelected: (seriesId) => selectedSeries = seriesId,
      onAnnotationTap: (annotation) => tappedAnnotation = annotation,
      onAnnotationDragged: (annotation, position) {
        draggedAnnotation = annotation;
        draggedPosition = position;
      },
      onSeriesDeselected: (seriesId) => deselectedSeries = seriesId,
    );
    final configuration = _success(
      ChartDocumentHydrator.hydrateDocument(
        _portableDocument(),
        runtimeBindings: bindings,
      ),
    ).value;

    await tester.pumpWidget(_host(configuration.build()));
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    const point = ChartDataPoint(x: 2, y: 20);
    final annotation = ThresholdAnnotation(
      id: 'runtime-threshold',
      axis: AnnotationAxis.y,
      value: 15,
    );
    chart.onPointTap?.call(point, 'series');
    chart.onPointHover?.call(point, 'series');
    chart.onBackgroundTap?.call(const Offset(12, 24));
    chart.onSeriesSelected?.call('series');
    chart.onAnnotationTap?.call(annotation);
    chart.onAnnotationDragged?.call(annotation, const Offset(36, 48));
    chart.onSeriesDeselected?.call('series');

    expect(tappedPoint, same(point));
    expect(tappedSeries, 'series');
    expect(hoveredPoint, same(point));
    expect(hoveredSeries, 'series');
    expect(backgroundPosition, const Offset(12, 24));
    expect(selectedSeries, 'series');
    expect(tappedAnnotation, same(annotation));
    expect(draggedAnnotation, same(annotation));
    expect(draggedPosition, const Offset(36, 48));
    expect(deselectedSeries, 'series');
  });

  testWidgets('two hydrated tiles keep controller state independent', (
    tester,
  ) async {
    final configuration = _success(
      ChartDocumentHydrator.hydrateDocument(_portableDocument()),
    ).value;
    final firstController = BravenChartController();
    final secondController = BravenChartController();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 360,
                  child: configuration.build(
                    bravenChartController: firstController,
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 360,
                  child: configuration.build(
                    bravenChartController: secondController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    firstController.setSeriesVisible('series', false);
    await tester.pump();
    final firstBeforeSelection = _success(
      firstController.extractDocument(),
    ).value;
    firstController.selectPoint(
      const ChartPointRef(seriesId: 'series', pointIndex: 0),
      revision: firstBeforeSelection.revision,
    );

    final first = _success(firstController.extractDocument()).value;
    final second = _success(secondController.extractDocument()).value;

    expect(first.viewState?.hiddenSeriesIds, {'series'});
    expect(first.viewState?.selectedPointRefs, const [
      ChartPointRef(seriesId: 'series', pointIndex: 0),
    ]);
    expect(second.viewState?.hiddenSeriesIds, isEmpty);
    expect(second.viewState?.selectedPointRefs, isEmpty);
  });

  test('rehydrates registered formatters and warns on safe fallback', () {
    final registeredDescriptor = ChartFormatterDescriptor(
      id: 'com.example.watts',
      arguments: const {'suffix': JsonStringValue(' W')},
    ).toDocument();
    final registered = _success(
      ChartDocumentHydrator.hydrateDocument(
        _portableDocument(xFormatter: registeredDescriptor),
        runtimeBindings: ChartRuntimeBindings(
          formatters: ChartFormatterRegistry(
            customFormatters: {
              'com.example.watts': (value, arguments) =>
                  '${value.toStringAsFixed(0)}${arguments['suffix']?.toJson()}',
            },
          ),
        ),
      ),
    );
    expect(registered.value.xAxis.labelFormatter?.call(250), '250 W');
    expect(registered.warnings, isEmpty);

    final missingDescriptor = ChartFormatterDescriptor(
      id: 'com.example.missing',
      fallbackPattern: '{value} units',
    ).toDocument();
    final missing = _success(
      ChartDocumentHydrator.hydrateDocument(
        _portableDocument(xFormatter: missingDescriptor),
      ),
    );
    expect(missing.value.xAxis.labelFormatter?.call(4.5), '4.5 units');
    expect(
      missing.warnings.single.code,
      ChartArtifactDiagnosticCodes.unregisteredFormatter,
    );
  });

  test('rejects unsupported required capabilities', () {
    final source = _portableDocument();
    final document = ChartDocument(
      documentId: source.documentId,
      revision: source.revision,
      series: source.series,
      xAxis: source.xAxis,
      axes: source.axes,
      theme: source.theme,
      interaction: source.interaction,
      requiredCapabilities: const {'com.example.future-series'},
    );

    final result = ChartDocumentHydrator.hydrateDocument(document);

    expect(result, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
    expect(
      (result as ChartArtifactFailure<HydratedChartConfiguration>).error.code,
      ChartArtifactDiagnosticCodes.missingRequiredCapability,
    );
  });

  test('hydrates a registered custom series extension codec', () {
    final source = _portableDocument();
    final customSeries = ChartSeriesDocument(
      type: 'com.example.line',
      id: 'custom',
      data: InlinePointPayload([
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(1),
          y: ChartNumberDocument.fromDouble(42),
        ),
      ]),
      requiredCapabilities: const {'series.com.example.line'},
    );
    final document = ChartDocument(
      documentId: source.documentId,
      revision: source.revision,
      series: [customSeries],
      xAxis: source.xAxis,
      axes: source.axes,
      theme: source.theme,
      interaction: source.interaction,
      legend: source.legend,
      grid: source.grid,
      layout: source.layout,
      normalization: source.normalization,
    );

    final hydrated = _success(
      ChartDocumentHydrator.hydrateDocument(
        document,
        runtimeBindings: const ChartRuntimeBindings(
          extensions: ChartExtensionRegistry(
            seriesCodecs: {'com.example.line': _CustomSeriesCodec()},
          ),
        ),
      ),
    ).value;

    expect(hydrated.series.single, isA<LineChartSeries>());
    expect(hydrated.series.single.points.single.y, 42);
  });

  test('validates and hydrates a JSON artifact envelope', () {
    final artifact = ChartArtifact(
      artifactId: 'hydration-json',
      renderer: const ChartRendererInfo(
        package: 'braven_charts',
        version: 'test',
      ),
      createdAt: DateTime.utc(2026, 7, 14),
      document: _portableDocument(),
    );
    final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;

    final hydrated = _success(ChartDocumentHydrator.hydrateJson(encoded)).value;

    expect(hydrated.series.single.id, 'series');
    expect(hydrated.series.single.points.single.y, 10);
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 700, height: 420, child: child)),
  ),
);

ChartDocument _portableDocument({
  JsonObjectValue? xFormatter,
  ChartTheme? theme,
  ChartThemeDocument? themeDocument,
}) {
  final series = _success(
    ChartSeriesDocumentCodec.encode(
      const LineChartSeries(
        id: 'series',
        name: 'Series',
        points: [ChartDataPoint(x: 1, y: 10)],
      ),
    ),
  ).value;
  final xAxis = _success(
    ChartAxisDocumentCodec.encodeXAxis(
      XAxisConfig(
        label: 'Time',
        labelFormatter: xFormatter == null ? null : (value) => '$value',
      ),
      formatter: xFormatter,
    ),
  ).value;
  final yAxis = _success(
    ChartAxisDocumentCodec.encodeYAxis(
      YAxisConfig(position: YAxisPosition.left).copyWith(id: 'y'),
    ),
  ).value;
  final encodedTheme =
      themeDocument ??
      _success(ChartThemeDocumentCodec.encode(theme ?? ChartTheme.light)).value;
  final interaction = _success(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value;
  final legend = _success(
    ChartConfigurationDocumentCodec.encodeLegend(
      visible: true,
      style: const LegendStyle(),
    ),
  ).value;

  return ChartDocument(
    documentId: 'portable',
    revision: 0,
    series: [series],
    xAxis: xAxis,
    axes: [yAxis],
    theme: encodedTheme,
    interaction: interaction,
    legend: legend,
    grid: ChartConfigurationDocumentCodec.encodeGrid(const GridConfig()),
    normalization: ChartConfigurationDocumentCodec.encodeNormalization(
      NormalizationMode.none,
    ),
  );
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}

String _themeFingerprint(ChartTheme theme) => canonicalJsonEncode(
  _success(
    ChartThemeDocumentCodec.encode(
      theme,
      captureMode: ChartThemeCaptureMode.resolvedOnly,
    ),
  ).value.resolved.toJson(),
);

class _CustomSeriesCodec implements ChartSeriesExtensionCodec {
  const _CustomSeriesCodec();

  @override
  String get typeId => 'com.example.line';

  @override
  String get capabilityId => 'series.com.example.line';

  @override
  int get codecVersion => 1;

  @override
  ChartSeriesDocument encode(ChartSeries value) => ChartSeriesDocument(
    type: typeId,
    id: value.id,
    name: value.name,
    data: InlinePointPayload([
      for (final point in value.points)
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(point.x),
          y: ChartNumberDocument.fromDouble(point.y),
        ),
    ]),
    requiredCapabilities: {capabilityId},
  );

  @override
  ChartSeries decode(ChartSeriesDocument document) {
    final payload = document.data as InlinePointPayload;
    return LineChartSeries(
      id: document.id,
      name: document.name,
      points: [
        for (final point in payload.points)
          ChartDataPoint(x: point.x.asDouble, y: point.y.asDouble),
      ],
    );
  }
}
