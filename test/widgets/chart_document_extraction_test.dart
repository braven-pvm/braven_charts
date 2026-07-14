import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detached controller returns a structured failure', () {
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    final result = controller.extractDocument();

    expect(result, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    expect(
      (result as ChartArtifactFailure<ChartDocumentSnapshot>).error.code,
      ChartArtifactDiagnosticCodes.chartNotAttached,
    );
  });

  testWidgets(
    'extracts widget, ChartController, AnnotationController, and view state',
    (tester) async {
      final bravenController = BravenChartController();
      final dataController = ChartController()
        ..addPoint('power', const ChartDataPoint(x: 2, y: 240))
        ..addAnnotation(
          ThresholdAnnotation(
            id: 'controller-threshold',
            axis: AnnotationAxis.y,
            value: 230,
          ),
        );
      final annotationController = AnnotationController(
        initialAnnotations: [
          ThresholdAnnotation(
            id: 'editable-threshold',
            axis: AnnotationAxis.y,
            value: 250,
          ),
        ],
      );
      addTearDown(bravenController.dispose);
      addTearDown(dataController.dispose);
      addTearDown(annotationController.dispose);

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: bravenController,
            controller: dataController,
            annotationController: annotationController,
            title: 'Power trace',
            series: const [
              LineChartSeries(
                id: 'power',
                name: 'Power',
                points: [ChartDataPoint(x: 1, y: 200)],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      bravenController.selectSeries('power');
      annotationController.selectAnnotation('editable-threshold');

      final result = bravenController.extractDocument(
        const ChartDocumentExtractOptions(documentId: 'power-trace'),
      );
      final snapshot = _success(result).value;
      final payload =
          snapshot.document.series.single.data as InlinePointPayload;
      final roundTripped = ChartDocument.fromJson(snapshot.document.toJson());

      expect(snapshot.document.documentId, 'power-trace');
      expect(snapshot.document.title, 'Power trace');
      expect(payload.points.map((point) => point.y.asDouble), [200, 240]);
      expect(
        snapshot.document.annotations.map((annotation) => annotation.id),
        containsAll(['controller-threshold', 'editable-threshold']),
      );
      expect(snapshot.viewState?.selectedSeriesId, 'power');
      expect(snapshot.viewState?.selectedAnnotationId, 'editable-threshold');
      expect(snapshot.viewState?.visibleBounds, isNotNull);
      expect(roundTripped.toJson(), snapshot.document.toJson());
    },
  );

  testWidgets('document revision advances with effective annotation edits', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final annotations = AnnotationController();
    addTearDown(bravenController.dispose);
    addTearDown(annotations.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          annotationController: annotations,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final first = _success(bravenController.extractDocument()).value;
    final unchanged = _success(bravenController.extractDocument()).value;
    annotations.addAnnotation(
      ThresholdAnnotation(id: 'threshold', axis: AnnotationAxis.y, value: 12),
    );
    await tester.pump();
    final changed = _success(bravenController.extractDocument()).value;

    expect(unchanged.document.revision, first.document.revision);
    expect(changed.document.revision, first.document.revision + 1);
    expect(annotations.revision, 1);
  });

  testWidgets('supports declared-source and configuration-only scopes', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final dataController = ChartController()
      ..addPoint('series', const ChartDataPoint(x: 2, y: 20));
    addTearDown(bravenController.dispose);
    addTearDown(dataController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          controller: dataController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final declared = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.declaredSource,
        ),
      ),
    ).value;
    final configuration = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.configurationOnly,
          includeViewState: false,
        ),
      ),
    ).value;

    expect(declared.document.pointCount, 1);
    expect(configuration.document.series, isEmpty);
    expect(configuration.viewState, isNull);
    expect(configuration.document.revision, declared.document.revision + 1);
  });

  testWidgets('keeps hidden series in full scope and filters visible scope', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    addTearDown(bravenController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          series: [
            _series(),
            const LineChartSeries(
              id: 'hidden',
              name: 'Hidden',
              points: [ChartDataPoint(x: 1, y: 30)],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    bravenController.setSeriesVisible('hidden', false);
    await tester.pump();

    final full = _success(bravenController.extractDocument()).value;
    final visible = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.visibleSeries,
        ),
      ),
    ).value;

    expect(full.document.series.map((series) => series.id), [
      'series',
      'hidden',
    ]);
    expect(full.viewState?.hiddenSeriesIds, {'hidden'});
    expect(visible.document.series.map((series) => series.id), ['series']);
    expect(bravenController.hiddenSeriesIds, {'hidden'});
  });

  testWidgets('visible viewport retains adjacent continuous-line points', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    addTearDown(bravenController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          xAxisConfig: const XAxisConfig(min: 2, max: 3),
          series: const [
            LineChartSeries(
              id: 'line',
              points: [
                ChartDataPoint(x: 0, y: 0),
                ChartDataPoint(x: 1, y: 1),
                ChartDataPoint(x: 2, y: 2),
                ChartDataPoint(x: 3, y: 3),
                ChartDataPoint(x: 4, y: 4),
                ChartDataPoint(x: 5, y: 5),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final snapshot = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.visibleViewport,
        ),
      ),
    ).value;
    final points =
        (snapshot.document.series.single.data as InlinePointPayload).points;

    expect(points.map((point) => point.x.asDouble), [1, 2, 3, 4]);
  });

  testWidgets('captures visible and overflow Y-axis slots', (tester) async {
    final bravenController = BravenChartController();
    addTearDown(bravenController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          maxAxesPerSide: 1,
          series: [
            LineChartSeries(
              id: 'power',
              points: const [ChartDataPoint(x: 1, y: 200)],
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.left,
                label: 'Power',
              ),
            ),
            LineChartSeries(
              id: 'torque',
              points: const [ChartDataPoint(x: 1, y: 40)],
              yAxisConfig: YAxisConfig(
                position: YAxisPosition.left,
                label: 'Torque',
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final viewState = _success(
      bravenController.extractDocument(),
    ).value.viewState!;

    expect(viewState.visibleAxisIds, hasLength(1));
    expect(viewState.overflowAxisIds, hasLength(1));
    expect(
      viewState.visibleAxisIds.toSet().intersection(
        viewState.overflowAxisIds.toSet(),
      ),
      isEmpty,
    );
  });

  testWidgets('includes direct LiveStreamController points', (tester) async {
    final bravenController = BravenChartController();
    final liveController = LiveStreamController(seriesId: 'series')
      ..addPoint(const ChartDataPoint(x: 2, y: 22));
    addTearDown(bravenController.dispose);
    addTearDown(liveController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          liveStreamController: liveController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final snapshot = _success(bravenController.extractDocument()).value;
    final payload = snapshot.document.series.single.data as InlinePointPayload;

    expect(payload.points.map((point) => point.y.asDouble), [10, 22]);
  });

  testWidgets('includes legacy stream points', (tester) async {
    final bravenController = BravenChartController();
    final streamController = StreamController<ChartDataPoint>();
    addTearDown(bravenController.dispose);
    addTearDown(streamController.close);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          dataStream: streamController.stream,
          series: [_series()],
        ),
      ),
    );
    streamController.add(const ChartDataPoint(x: 2, y: 21));
    await tester.pump();

    final snapshot = _success(bravenController.extractDocument()).value;
    final payload = snapshot.document.series.single.data as InlinePointPayload;

    expect(payload.points.map((point) => point.y.asDouble), [10, 21]);
  });

  testWidgets('includes paused LiveStreamController buffer points', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final liveController = LiveStreamController(seriesId: 'series')
      ..addPoint(const ChartDataPoint(x: 2, y: 22))
      ..pause()
      ..addPoint(const ChartDataPoint(x: 3, y: 33));
    addTearDown(bravenController.dispose);
    addTearDown(liveController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          liveStreamController: liveController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final snapshot = _success(bravenController.extractDocument()).value;
    final payload = snapshot.document.series.single.data as InlinePointPayload;

    expect(payload.points.map((point) => point.y.asDouble), [10, 22, 33]);
  });

  testWidgets('fails after bounded unstable revision attempts', (tester) async {
    final bravenController = BravenChartController();
    final liveController = _UnstableLiveStreamController();
    addTearDown(bravenController.dispose);
    addTearDown(liveController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          liveStreamController: liveController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final result = bravenController.extractDocument(
      const ChartDocumentExtractOptions(maxSnapshotAttempts: 2),
    );

    expect(result, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    expect(
      (result as ChartArtifactFailure<ChartDocumentSnapshot>).error.code,
      ChartArtifactDiagnosticCodes.unstableStreamRevision,
    );
  });

  testWidgets('keeps extraction state independent across mounted charts', (
    tester,
  ) async {
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
                  child: BravenChartPlus(
                    bravenChartController: firstController,
                    series: const [
                      LineChartSeries(
                        id: 'first',
                        points: [ChartDataPoint(x: 1, y: 10)],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 360,
                  child: BravenChartPlus(
                    bravenChartController: secondController,
                    series: const [
                      LineChartSeries(
                        id: 'second',
                        points: [ChartDataPoint(x: 1, y: 20)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    firstController.setSeriesVisible('first', false);
    await tester.pump();

    final first = _success(
      firstController.extractDocument(
        const ChartDocumentExtractOptions(documentId: 'first-document'),
      ),
    ).value;
    final second = _success(
      secondController.extractDocument(
        const ChartDocumentExtractOptions(documentId: 'second-document'),
      ),
    ).value;

    expect(first.document.series.single.id, 'first');
    expect(first.viewState?.hiddenSeriesIds, {'first'});
    expect(second.document.series.single.id, 'second');
    expect(second.viewState?.hiddenSeriesIds, isEmpty);
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 700, height: 420, child: child)),
  ),
);

LineChartSeries _series() => const LineChartSeries(
  id: 'series',
  name: 'Series',
  points: [ChartDataPoint(x: 1, y: 10)],
);

ChartArtifactSuccess<ChartDocumentSnapshot> _success(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return result as ChartArtifactSuccess<ChartDocumentSnapshot>;
}

class _UnstableLiveStreamController extends LiveStreamController {
  _UnstableLiveStreamController() : super(seriesId: 'series');

  int _readRevision = 0;

  @override
  int get committedDataRevision => _readRevision++;
}
