import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/artifacts/chart_document_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('artifact pipeline reports timings by dataset size', () {
    for (final pointCount in [100, 10000, 100000]) {
      final source = _source(pointCount);

      final extractionWatch = Stopwatch()..start();
      final snapshot = _success(
        ChartDocumentExtractor.extract(
          source: source,
          options: ChartDocumentExtractOptions(
            documentId: 'pipeline-benchmark-$pointCount',
            dataStorage: ChartDataStorage.inlineColumns,
          ),
          revision: 7,
        ),
      ).value;
      extractionWatch.stop();

      final artifact = ChartArtifact(
        artifactId: 'pipeline-benchmark-$pointCount',
        renderer: const ChartRendererInfo(
          package: 'braven_charts',
          version: 'benchmark',
        ),
        createdAt: DateTime.utc(2026, 7, 15),
        document: snapshot.document,
        viewState: snapshot.viewState,
      );
      final encodeWatch = Stopwatch()..start();
      final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;
      encodeWatch.stop();

      final hydrationWatch = Stopwatch()..start();
      final hydrated = _success(
        ChartDocumentHydrator.hydrateJson(encoded),
      ).value;
      hydrationWatch.stop();

      final tableWatch = Stopwatch()..start();
      final table = ChartTableModel.fromDocument(
        snapshot.document,
        viewState: snapshot.viewState,
        options: const ChartTableOptions(
          rowLayout: ChartTableRowLayout.wide,
          alignmentPolicy: ChartTableAlignmentPolicy.exactX,
        ),
      );
      tableWatch.stop();

      expect(snapshot.document.pointCount, pointCount);
      expect(hydrated.series.single.points, hasLength(pointCount));
      expect(table.rowCount, pointCount);
      expect(extractionWatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(encodeWatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(hydrationWatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(tableWatch.elapsed, lessThan(const Duration(seconds: 5)));
      // ignore: avoid_print
      print(
        'Artifact pipeline ($pointCount points): '
        'extract ${_ms(extractionWatch.elapsed)}ms; '
        'encode ${_ms(encodeWatch.elapsed)}ms; '
        'hydrate ${_ms(hydrationWatch.elapsed)}ms; '
        'table ${_ms(tableWatch.elapsed)}ms; '
        'JSON ${encoded.length} chars',
      );
    }
  });

  test('multiple hydrated comparison configurations stay bounded', () {
    final snapshot = _success(
      ChartDocumentExtractor.extract(
        source: _source(10000),
        options: const ChartDocumentExtractOptions(
          documentId: 'comparison-benchmark',
          dataStorage: ChartDataStorage.inlineColumns,
        ),
        revision: 1,
      ),
    ).value;

    final watch = Stopwatch()..start();
    final configurations = [
      for (var index = 0; index < 8; index++)
        _success(
          ChartDocumentHydrator.hydrateDocument(snapshot.document),
        ).value,
    ];
    watch.stop();

    expect(configurations, hasLength(8));
    expect(
      configurations.every(
        (configuration) => configuration.series.single.points.length == 10000,
      ),
      isTrue,
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    // ignore: avoid_print
    print(
      'Eight independent 10K-point configurations: ${_ms(watch.elapsed)}ms',
    );
  });

  test('dense Range Area artifact and source generation stay bounded', () {
    const pointCount = 5000;
    final extractionWatch = Stopwatch()..start();
    final snapshot = _success(
      ChartDocumentExtractor.extract(
        source: _rangeAreaSource(pointCount),
        options: const ChartDocumentExtractOptions(
          documentId: 'range-area-portable-benchmark',
          dataStorage: ChartDataStorage.inlineColumns,
        ),
        revision: 1,
      ),
    ).value;
    extractionWatch.stop();

    final artifact = ChartArtifact(
      artifactId: 'range-area-portable-benchmark',
      renderer: const ChartRendererInfo(
        package: 'braven_charts',
        version: 'benchmark',
      ),
      createdAt: DateTime.utc(2026, 7, 21),
      document: snapshot.document,
      viewState: snapshot.viewState,
    );
    final encodeWatch = Stopwatch()..start();
    final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;
    encodeWatch.stop();

    final hydrateWatch = Stopwatch()..start();
    final hydrated = _success(ChartDocumentHydrator.hydrateJson(encoded)).value;
    hydrateWatch.stop();

    final sourceWatch = Stopwatch()..start();
    final generated = _success(
      ChartDartSourceGenerator.generate(
        snapshot,
        options: const ChartDartSourceOptions(
          variableName: 'denseRangeAreaChart',
          maxInlinePoints: pointCount,
        ),
      ),
    ).value;
    sourceWatch.stop();

    expect(snapshot.document.pointCount, pointCount);
    expect(hydrated.series.single, isA<RangeAreaChartSeries>());
    expect(hydrated.series.single.points, hasLength(pointCount));
    expect(generated.pointCount, pointCount);
    expect(generated.omittedPointCount, 0);
    expect(generated.source, contains('RangeAreaDataPoint('));
    for (final duration in [
      extractionWatch.elapsed,
      encodeWatch.elapsed,
      hydrateWatch.elapsed,
      sourceWatch.elapsed,
    ]) {
      expect(duration, lessThan(const Duration(seconds: 5)));
    }
    // ignore: avoid_print
    print(
      'Range Area portable pipeline ($pointCount intervals): '
      'extract ${_ms(extractionWatch.elapsed)}ms; '
      'encode ${_ms(encodeWatch.elapsed)}ms; '
      'hydrate ${_ms(hydrateWatch.elapsed)}ms; '
      'source ${_ms(sourceWatch.elapsed)}ms; '
      'JSON ${encoded.length} chars; Dart ${generated.source.length} chars',
    );
  });

  testWidgets('streaming snapshot reports bounded extraction impact', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final liveController = LiveStreamController(
      seriesId: 'stream',
      maxPoints: 10000,
      autoScroll: false,
    );
    addTearDown(bravenController.dispose);
    addTearDown(liveController.dispose);
    for (var index = 0; index < 10000; index++) {
      liveController.addPoint(
        ChartDataPoint(x: index.toDouble(), y: 120 + (index % 80).toDouble()),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 500,
            child: BravenChartPlus(
              bravenChartController: bravenController,
              liveStreamController: liveController,
              series: const [
                LineChartSeries(id: 'stream', name: 'Stream', points: []),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final watch = Stopwatch()..start();
    final snapshot = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          documentId: 'streaming-snapshot-benchmark',
          dataStorage: ChartDataStorage.inlineColumns,
        ),
      ),
    ).value;
    watch.stop();

    expect(snapshot.document.pointCount, 10000);
    expect(liveController.pointCount, 10000);
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    // ignore: avoid_print
    print('10K committed streaming snapshot: ${_ms(watch.elapsed)}ms');
  });

  testWidgets('virtualized 100K-row table reports initial render and scroll', (
    tester,
  ) async {
    final snapshot = _success(
      ChartDocumentExtractor.extract(
        source: _source(100000),
        options: const ChartDocumentExtractOptions(
          documentId: 'table-render-benchmark',
          dataStorage: ChartDataStorage.inlineColumns,
        ),
        revision: 1,
      ),
    ).value;
    final model = ChartTableModel.fromDocument(snapshot.document);

    final renderWatch = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 700,
            child: ChartDataTable(model: model),
          ),
        ),
      ),
    );
    renderWatch.stop();

    final scrollWatch = Stopwatch()..start();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    scrollWatch.stop();

    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(renderWatch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(scrollWatch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print(
      '100K-row virtualized table: render ${_ms(renderWatch.elapsed)}ms; '
      'scroll ${_ms(scrollWatch.elapsed)}ms',
    );
  });

  testWidgets('workbench mode switches and table refreshes stay bounded', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    var chartBuilds = 0;
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    final series = <ChartSeries>[
      for (var seriesIndex = 0; seriesIndex < 3; seriesIndex++)
        LineChartSeries(
          id: 'series-$seriesIndex',
          name: 'Series $seriesIndex',
          points: [
            for (var pointIndex = 0; pointIndex < 2000; pointIndex++)
              ChartDataPoint(
                x: pointIndex.toDouble(),
                y: 100 + seriesIndex * 20 + (pointIndex % 120) * 0.5,
              ),
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 700,
            child: BravenChartWorkbench(
              chartController: chartController,
              workbenchController: workbenchController,
              tableRefreshPolicy: ChartTableRefreshPolicy.manual,
              chartBuilder: (context, controller) {
                chartBuilds++;
                return BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  series: series,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final watch = Stopwatch()..start();
    for (var iteration = 0; iteration < 12; iteration++) {
      workbenchController.setDisplayMode(ChartDisplayMode.data);
      await tester.pumpAndSettle();
      workbenchController.refreshTable();
      await tester.pumpAndSettle();
      workbenchController.setDisplayMode(ChartDisplayMode.split);
      await tester.pumpAndSettle();
      workbenchController.setDisplayMode(ChartDisplayMode.chart);
      await tester.pumpAndSettle();
    }
    watch.stop();

    expect(chartBuilds, 1);
    expect(workbenchController.tableModel?.rowCount, 2000);
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print('12 workbench mode cycles with 6K points: ${_ms(watch.elapsed)}ms');
  });
}

ChartDocumentExtractionSource _source(int pointCount) {
  final series = LineChartSeries(
    id: 'power',
    name: 'Power',
    unit: 'W',
    color: const Color(0xFF2563EB),
    points: [
      for (var index = 0; index < pointCount; index++)
        ChartDataPoint(x: index.toDouble(), y: 180 + (index % 400) * 0.25),
    ],
  );
  final theme = ChartTheme.light;
  return ChartDocumentExtractionSource(
    allSeries: [series],
    visibleSeries: [series],
    declaredSeries: [series],
    annotations: const [],
    xAxis: const XAxisConfig(label: 'Sample'),
    axes: [
      YAxisConfig.withId(
        id: 'y',
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
      ),
    ],
    theme: theme,
    interaction: const InteractionConfig(),
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
  );
}

ChartDocumentExtractionSource _rangeAreaSource(int pointCount) {
  final series = RangeAreaChartSeries(
    id: 'confidence-band',
    name: 'Confidence band',
    unit: '%',
    color: const Color(0xFF7C3AED),
    interpolation: LineInterpolation.monotone,
    points: [
      for (var index = 0; index < pointCount; index++)
        RangeAreaDataPoint(
          x: index.toDouble(),
          low: 40 + (index % 120) * .2,
          high: 52 + (index % 120) * .2,
        ),
    ],
  );
  final theme = ChartTheme.light;
  return ChartDocumentExtractionSource(
    allSeries: [series],
    visibleSeries: [series],
    declaredSeries: [series],
    annotations: const [],
    xAxis: const XAxisConfig(label: 'Sample'),
    axes: [
      YAxisConfig.withId(
        id: 'y',
        position: YAxisPosition.left,
        label: 'Confidence',
        unit: '%',
      ),
    ],
    theme: theme,
    interaction: const InteractionConfig(),
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
  );
}

String _ms(Duration duration) =>
    (duration.inMicroseconds / Duration.microsecondsPerMillisecond)
        .toStringAsFixed(3);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
