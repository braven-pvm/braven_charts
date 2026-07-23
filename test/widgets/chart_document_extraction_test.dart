import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
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
    'outgoing chart cannot detach a replacement using the same controller',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      var replacement = false;
      late StateSetter setHostState;

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return BravenChartPlus(
                key: ValueKey(replacement),
                bravenChartController: controller,
                series: [
                  LineChartSeries(
                    id: replacement ? 'replacement' : 'original',
                    points: const [ChartDataPoint(x: 1, y: 10)],
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();

      setHostState(() => replacement = true);
      await tester.pump();

      final snapshot = _success(controller.extractDocument()).value;
      expect(snapshot.document.series.single.id, 'replacement');
    },
  );

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

  testWidgets('snapshot carries the controller effective revision signal', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final dataController = ChartController();
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

    final first = _success(bravenController.extractDocument()).value;
    expect(
      first.revision,
      same(bravenController.effectiveDocumentRevision.value),
    );

    dataController.addPoint('series', const ChartDataPoint(x: 2, y: 20));
    await tester.pump();
    final changedSignal = bravenController.effectiveDocumentRevision.value;
    final changed = _success(bravenController.extractDocument()).value;

    expect(changedSignal, isNot(same(first.revision)));
    expect(changed.revision, same(changedSignal));
  });

  testWidgets('transient pointer motion does not change document revision', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    addTearDown(bravenController.dispose);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();
    final before = bravenController.effectiveDocumentRevision.value;
    final center = tester.getCenter(find.byType(BravenChartPlus));
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: center);
    await tester.pump();
    await pointer.moveTo(center + const Offset(12, 6));
    await tester.pump();

    expect(bravenController.effectiveDocumentRevision.value, same(before));
    await pointer.removePointer();
  });

  testWidgets(
    'point commands validate revisions and separate focus from selection',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      const point = ChartPointRef(seriesId: 'series', pointIndex: 0);

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: [_series()],
          ),
        ),
      );
      await tester.pump();
      final first = _success(controller.extractDocument()).value;

      expect(
        controller.focusPoint(point, revision: first.revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.focusedPointRefs, {point});
      expect(controller.selectedPointRefs, isEmpty);
      expect(controller.effectiveDocumentRevision.value, same(first.revision));

      final invalid = controller.selectPoint(
        const ChartPointRef(seriesId: 'series', pointIndex: 99),
        revision: first.revision,
      );
      expect(invalid, isA<ChartArtifactFailure<void>>());
      expect(
        (invalid as ChartArtifactFailure<void>).error.code,
        ChartArtifactDiagnosticCodes.invalidPointReference,
      );
      expect(controller.selectedPointRefs, isEmpty);

      expect(
        controller.selectPoint(point, revision: first.revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      final selected = _success(controller.extractDocument()).value;
      expect(selected.viewState?.selectedPointRefs, [point]);
      expect(controller.selectedPointRefs, {point});

      final stale = controller.focusPoint(point, revision: first.revision);
      expect(stale, isA<ChartArtifactFailure<void>>());
      expect(
        (stale as ChartArtifactFailure<void>).error.code,
        ChartArtifactDiagnosticCodes.stalePointReference,
      );
      expect(controller.focusedPointRefs, {point});

      controller.clearPointFocus();
      controller.clearPointSelection();
      expect(controller.focusedPointRefs, isEmpty);
      expect(controller.selectedPointRefs, isEmpty);
    },
  );

  testWidgets('hidden-series point selection is retained deterministically', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const point = ChartPointRef(seriesId: 'series', pointIndex: 0);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(bravenChartController: controller, series: [_series()]),
      ),
    );
    await tester.pump();
    controller.setSeriesVisible('series', false);
    await tester.pump();
    final hidden = _success(controller.extractDocument()).value;

    expect(
      controller.selectPoint(point, revision: hidden.revision),
      isA<ChartArtifactSuccess<void>>(),
    );
    final selected = _success(controller.extractDocument()).value;

    expect(selected.viewState?.hiddenSeriesIds, {'series'});
    expect(selected.viewState?.selectedPointRefs, [point]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('point selection can be additive and reveal an offscreen X', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const firstPoint = ChartPointRef(seriesId: 'series', pointIndex: 0);
    const secondPoint = ChartPointRef(seriesId: 'series', pointIndex: 1);
    const lastPoint = ChartPointRef(seriesId: 'series', pointIndex: 2);

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          series: const [
            LineChartSeries(
              id: 'series',
              points: [
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 5, y: 2),
                ChartDataPoint(x: 10, y: 3),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final initial = _success(controller.extractDocument()).value;
    controller.selectPoint(firstPoint, revision: initial.revision);
    final afterFirst = _success(controller.extractDocument()).value;
    controller.selectPoint(
      secondPoint,
      revision: afterFirst.revision,
      additive: true,
    );
    expect(controller.selectedPointRefs, {firstPoint, secondPoint});

    controller.restoreViewState(
      ChartViewState(
        visibleBounds: const ChartBoundsDocument(
          xMin: 0,
          xMax: 1,
          yMin: 0,
          yMax: 4,
        ),
        selectedPointRefs: const [firstPoint, secondPoint],
      ),
    );
    await tester.pump();
    await tester.pump();
    final narrowed = _success(controller.extractDocument()).value;
    expect(narrowed.viewState?.visibleBounds?.xMax, 1);

    controller.focusPoint(lastPoint, revision: narrowed.revision, reveal: true);
    final revealed = _success(controller.extractDocument()).value;
    expect(revealed.viewState!.visibleBounds!.xMin, lessThan(10));
    expect(revealed.viewState!.visibleBounds!.xMax, greaterThan(10));
  });

  testWidgets('coalesces direct streaming revision notifications', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    final liveController = LiveStreamController(seriesId: 'series');
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
    final before = bravenController.effectiveDocumentRevision.value;
    var signalChanges = 0;
    void listener() => signalChanges++;
    bravenController.effectiveDocumentRevision.addListener(listener);
    addTearDown(
      () => bravenController.effectiveDocumentRevision.removeListener(listener),
    );

    for (var index = 0; index < 20; index++) {
      liveController.addPoint(
        ChartDataPoint(x: index + 2, y: index.toDouble()),
      );
    }
    await tester.pump();
    await tester.pump();
    expect(liveController.effectiveDataRevision.value, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(signalChanges, 0);
    expect(bravenController.effectiveDocumentRevision.value, same(before));

    await tester.pump(const Duration(milliseconds: 60));
    expect(signalChanges, 1);
    expect(
      bravenController.effectiveDocumentRevision.value,
      isNot(same(before)),
    );
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

  testWidgets(
    'selection scope projects exact points or complete participating series',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: const [
              LineChartSeries(
                id: 'actual',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                  ChartDataPoint(x: 2, y: 30),
                ],
              ),
              LineChartSeries(
                id: 'plan',
                points: [
                  ChartDataPoint(x: 0, y: 12),
                  ChartDataPoint(x: 1, y: 22),
                  ChartDataPoint(x: 2, y: 32),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectPoints(const [
          ChartPointRef(seriesId: 'actual', pointIndex: 1),
          ChartPointRef(seriesId: 'plan', pointIndex: 2),
        ], revision: revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final selectedOnly = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      final participating = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
            selectionProjection: ChartSelectionProjectionOptions(
              seriesProjection:
                  ChartSelectionSeriesProjection.completeParticipatingSeries,
            ),
          ),
        ),
      ).value;

      expect(selectedOnly.document.series.map((series) => series.id), [
        'actual',
        'plan',
      ]);
      expect(
        selectedOnly.document.series.map(
          (series) =>
              (series.data as InlinePointPayload).points.single.x.asDouble,
        ),
        [1, 2],
      );
      expect(
        participating.document.series.map(
          (series) => (series.data as InlinePointPayload).points.length,
        ),
        [3, 3],
      );
      expect(selectedOnly.viewState?.visibleBounds, isNull);
      expect(selectedOnly.viewState?.selectedSeriesIds, isEmpty);
      expect(selectedOnly.viewState?.selectedPointRefs, isEmpty);

      controller.clearPointSelection();
      controller.selectSeriesIds(const ['actual']);
      await tester.pump();
      final wholeSeries = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      expect(wholeSeries.document.series.single.id, 'actual');
      expect(
        (wholeSeries.document.series.single.data as InlinePointPayload).points,
        hasLength(3),
      );
    },
  );

  testWidgets(
    'X-interval selection defaults to source points and can opt into exact Line boundaries',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: const [
              LineChartSeries(
                id: 'signal',
                interpolation: LineInterpolation.linear,
                isXOrdered: true,
                points: [
                  ChartDataPoint(x: 0, y: 0),
                  ChartDataPoint(x: 1, y: 10),
                  ChartDataPoint(x: 2, y: 20),
                  ChartDataPoint(x: 3, y: 30),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectExpression(
          ChartSelectionExpression(
            clauses: [
              ChartSelectionXIntervalClause(
                minimumXInclusive: 0.5,
                maximumXInclusive: 2.5,
                seriesIds: const {'signal'},
              ),
            ],
          ),
          revision: revision,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final sourceOnly = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      final interpolated = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
            selectionProjection: ChartSelectionProjectionOptions(
              intervalBoundaryProjection:
                  ChartSelectionIntervalBoundaryProjection
                      .interpolateContinuousSeries,
            ),
          ),
        ),
      ).value;
      final interpolatedPoints =
          (interpolated.document.series.single.data as InlinePointPayload)
              .points;
      final sourcePoints =
          (sourceOnly.document.series.single.data as InlinePointPayload).points;

      expect(interpolatedPoints.map((point) => point.x.asDouble), [
        0.5,
        1,
        2,
        2.5,
      ]);
      expect(interpolatedPoints.map((point) => point.y.asDouble), [
        5,
        10,
        20,
        25,
      ]);
      expect(sourcePoints.map((point) => point.x.asDouble), [1, 2]);
      expect(
        controller.selectionExpression.clauses.single,
        isA<ChartSelectionXIntervalClause>(),
      );

      final captured = _success(controller.extractDocument()).value;
      final portableExpression = captured.viewState!.selectionExpression!;
      final capturedClause = portableExpression.clauses.single;
      expect(capturedClause.kind, ChartSelectionClauseDocumentKind.xInterval);
      expect(capturedClause.minimumInclusive, 0.5);
      expect(capturedClause.maximumInclusive, 2.5);
      expect(capturedClause.seriesIds, {'signal'});

      controller.clearPointSelection();
      await tester.pump();
      expect(controller.selectionExpression.isEmpty, isTrue);

      controller.restoreViewState(
        ChartViewState.fromJson(captured.viewState!.toJson()),
      );
      await tester.pump();
      final restoredClause =
          controller.selectionExpression.clauses.single
              as ChartSelectionXIntervalClause;
      expect(restoredClause.minimumXInclusive, 0.5);
      expect(restoredClause.maximumXInclusive, 2.5);
      expect(restoredClause.seriesIds, {'signal'});
    },
  );

  testWidgets(
    'selection extraction keeps complete OHLC and Range Area tuples',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: [
              CandlestickChartSeries(
                id: 'ohlc',
                points: [
                  CandlestickDataPoint(
                    x: 0,
                    open: 10,
                    high: 14,
                    low: 8,
                    close: 12,
                  ),
                  CandlestickDataPoint(
                    x: 1,
                    open: 12,
                    high: 16,
                    low: 11,
                    close: 15,
                  ),
                ],
              ),
              RangeAreaChartSeries(
                id: 'range',
                points: [
                  RangeAreaDataPoint(x: 0, low: 20, high: 30),
                  RangeAreaDataPoint(x: 1, low: 22, high: 35),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectExpression(
          ChartSelectionExpression(
            clauses: [
              ChartSelectionXIntervalClause(
                minimumXInclusive: 0.5,
                maximumXInclusive: 1.5,
                seriesIds: const {'ohlc', 'range'},
              ),
            ],
          ),
          revision: revision,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final snapshot = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      final hydrated = _artifactSuccess(
        ChartDocumentHydrator.hydrateDocument(snapshot.document),
      ).value;
      final candle = hydrated.series.whereType<CandlestickChartSeries>().single;
      final range = hydrated.series.whereType<RangeAreaChartSeries>().single;

      expect(candle.points.single, isA<CandlestickDataPoint>());
      final candlePoint = candle.points.single as CandlestickDataPoint;
      expect(
        (
          candlePoint.x,
          candlePoint.open,
          candlePoint.high,
          candlePoint.low,
          candlePoint.close,
        ),
        (1, 12, 16, 11, 15),
      );
      expect(range.points.single, isA<RangeAreaDataPoint>());
      final rangePoint = range.points.single as RangeAreaDataPoint;
      expect((rangePoint.x, rangePoint.low, rangePoint.high), (1, 22, 35));
    },
  );

  testWidgets(
    'X interval between sparse Line markers still extracts exact boundaries',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: const [
              LineChartSeries(
                id: 'sparse',
                interpolation: LineInterpolation.linear,
                isXOrdered: true,
                points: [
                  ChartDataPoint(x: 0, y: 0),
                  ChartDataPoint(x: 1, y: 20),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectExpression(
          ChartSelectionExpression(
            clauses: [
              ChartSelectionXIntervalClause(
                minimumXInclusive: 0.25,
                maximumXInclusive: 0.75,
                seriesIds: const {'sparse'},
              ),
            ],
          ),
          revision: revision,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final extracted = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
            selectionProjection: ChartSelectionProjectionOptions(
              intervalBoundaryProjection:
                  ChartSelectionIntervalBoundaryProjection
                      .interpolateContinuousSeries,
            ),
          ),
        ),
      ).value;
      final points =
          (extracted.document.series.single.data as InlinePointPayload).points;
      expect(points.map((point) => point.x.asDouble), [0.25, 0.75]);
      expect(points.map((point) => point.y.asDouble), [5, 15]);

      final sourceOnly = controller.extractDocument(
        const ChartDocumentExtractOptions(dataScope: ChartDataScope.selection),
      );
      expect(sourceOnly, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    },
  );

  testWidgets('Area interval boundaries follow the configured monotone curve', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          series: const [
            AreaChartSeries(
              id: 'area',
              interpolation: LineInterpolation.monotone,
              isXOrdered: true,
              points: [
                ChartDataPoint(x: 0, y: 0),
                ChartDataPoint(x: 1, y: 10),
                ChartDataPoint(x: 2, y: 0),
                ChartDataPoint(x: 3, y: 10),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final revision = controller.effectiveDocumentRevision.value!;
    expect(
      controller.selectExpression(
        ChartSelectionExpression(
          clauses: [
            ChartSelectionXIntervalClause(
              minimumXInclusive: 0.5,
              maximumXInclusive: 1.5,
              seriesIds: const {'area'},
            ),
          ],
        ),
        revision: revision,
      ),
      isA<ChartArtifactSuccess<void>>(),
    );
    await tester.pump();

    final sourceOnly = _success(
      controller.extractDocument(
        const ChartDocumentExtractOptions(dataScope: ChartDataScope.selection),
      ),
    ).value;
    final extracted = _success(
      controller.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.selection,
          selectionProjection: ChartSelectionProjectionOptions(
            intervalBoundaryProjection: ChartSelectionIntervalBoundaryProjection
                .interpolateContinuousSeries,
          ),
        ),
      ),
    ).value;
    final points =
        (extracted.document.series.single.data as InlinePointPayload).points;
    final sourcePoints =
        (sourceOnly.document.series.single.data as InlinePointPayload).points;
    expect(sourcePoints.map((point) => point.x.asDouble), [1]);
    expect(sourcePoints.map((point) => point.y.asDouble), [10]);
    expect(points.map((point) => point.x.asDouble), [0.5, 1, 1.5]);
    expect(points.map((point) => point.y.asDouble), [7.5, 10, 5]);
  });

  testWidgets('radial selection recomputes shares from retained raw values', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          series: [
            PieChartSeries(
              id: 'mix',
              points: [
                const ChartDataPoint(x: 0, y: 10, label: 'A'),
                const ChartDataPoint(x: 1, y: 20, label: 'B'),
                const ChartDataPoint(x: 2, y: 70, label: 'C'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final revision = controller.effectiveDocumentRevision.value!;
    expect(
      controller.selectExpression(
        ChartSelectionExpression(
          clauses: const [
            ChartSelectionPointIndexSpanClause(
              seriesId: 'mix',
              startPointIndexInclusive: 0,
              endPointIndexInclusive: 1,
            ),
          ],
        ),
        revision: revision,
      ),
      isA<ChartArtifactSuccess<void>>(),
    );
    await tester.pump();

    final snapshot = _success(
      controller.extractDocument(
        const ChartDocumentExtractOptions(dataScope: ChartDataScope.selection),
      ),
    ).value;
    final hydrated = _artifactSuccess(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    ).value;
    final pie = hydrated.series.whereType<PieChartSeries>().single;

    expect(pie.points.map((point) => point.y), [10, 20]);
    expect(pie.total, 30);
    expect(pie.points.first.y / pie.total, closeTo(1 / 3, 1e-9));
    expect(pie.points.last.y / pie.total, closeTo(2 / 3, 1e-9));
  });

  testWidgets('selection scope fails clearly when nothing is selected', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        BravenChartPlus(bravenChartController: controller, series: [_series()]),
      ),
    );
    await tester.pump();

    final result = controller.extractDocument(
      const ChartDocumentExtractOptions(dataScope: ChartDataScope.selection),
    );

    expect(result, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    expect(
      (result as ChartArtifactFailure<ChartDocumentSnapshot>).error.code,
      ChartArtifactDiagnosticCodes.selectionEmpty,
    );
  });

  testWidgets(
    'selection scope rebases point annotations and clips data-space annotations',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            yAxis: YAxisConfig.withId(
              id: 'primary',
              position: YAxisPosition.left,
            ),
            series: [
              const LineChartSeries(
                id: 'actual',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                  ChartDataPoint(x: 2, y: 30),
                  ChartDataPoint(x: 3, y: 40),
                ],
              ),
              LineChartSeries(
                id: 'other',
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.right,
                  label: 'Other',
                ),
                points: const [ChartDataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              PointAnnotation(
                id: 'selected-point',
                seriesId: 'actual',
                dataPointIndex: 3,
              ),
              PointAnnotation(
                id: 'omitted-point',
                seriesId: 'actual',
                dataPointIndex: 0,
              ),
              ChordAnnotation(
                id: 'selected-chord',
                seriesId: 'actual',
                startIndex: 1,
                endIndex: 3,
                perpendicularIndex: 0,
              ),
              ErrorBarAnnotation(
                id: 'selected-errors',
                seriesId: 'actual',
                values: const [
                  ErrorBarDatum.symmetric(pointIndex: 1, y: 2),
                  ErrorBarDatum.symmetric(pointIndex: 2, y: 3),
                ],
              ),
              RangeAnnotation(
                id: 'clipped-range',
                startX: 0.5,
                endX: 4,
                startY: 15,
                endY: 45,
                seriesId: 'actual',
              ),
              ThresholdAnnotation(
                id: 'retained-threshold',
                axis: AnnotationAxis.y,
                value: 30,
                seriesId: 'actual',
              ),
              ThresholdAnnotation(
                id: 'omitted-threshold',
                axis: AnnotationAxis.y,
                value: 90,
                seriesId: 'actual',
              ),
              TrendAnnotation(
                id: 'omitted-derived-trend',
                seriesId: 'actual',
                trendType: TrendType.linear,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectPoints(const [
          ChartPointRef(seriesId: 'actual', pointIndex: 1),
          ChartPointRef(seriesId: 'actual', pointIndex: 3),
        ], revision: revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final result = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      );
      final hydratedResult = ChartDocumentHydrator.hydrateDocument(
        result.value.document,
      );
      expect(
        hydratedResult,
        isA<ChartArtifactSuccess<HydratedChartConfiguration>>(),
      );
      final hydrated =
          (hydratedResult as ChartArtifactSuccess<HydratedChartConfiguration>)
              .value;

      expect(result.value.document.axes.map((axis) => axis.id), ['primary']);
      expect(hydrated.annotations.map((annotation) => annotation.id), [
        'selected-point',
        'selected-chord',
        'selected-errors',
        'clipped-range',
        'retained-threshold',
      ]);
      final point = hydrated.annotations.whereType<PointAnnotation>().single;
      expect(point.dataPointIndex, 1);
      final chord = hydrated.annotations.whereType<ChordAnnotation>().single;
      expect((chord.startIndex, chord.endIndex), (0, 1));
      expect(chord.perpendicularIndex, isNull);
      final errorBars = hydrated.annotations
          .whereType<ErrorBarAnnotation>()
          .single;
      expect(errorBars.values.single.pointIndex, 0);
      final range = hydrated.annotations.whereType<RangeAnnotation>().single;
      expect((range.startX, range.endX), (1, 3));
      expect((range.startY, range.endY), (20, 40));
      expect(
        result.warnings
            .where(
              (warning) =>
                  warning.code ==
                  ChartArtifactDiagnosticCodes.selectionAnnotationOmitted,
            )
            .map((warning) => warning.path),
        containsAll([
          r'$.annotations[omitted-point]',
          r'$.annotations[omitted-threshold]',
          r'$.annotations[omitted-derived-trend]',
        ]),
      );
      expect(
        result.warnings.map((warning) => warning.code),
        contains(
          ChartArtifactDiagnosticCodes.selectionAnnotationComponentOmitted,
        ),
      );
      expect(
        ChartDocument.fromJson(result.value.document.toJson()).toJson(),
        result.value.document.toJson(),
      );

      controller.clearPointSelection();
      controller.selectSeriesIds(const ['actual']);
      await tester.pump();
      final completeSeries = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      expect(
        completeSeries.document.annotations.map((annotation) => annotation.id),
        contains('omitted-derived-trend'),
      );
    },
  );

  testWidgets('selection annotation projection can omit every annotation', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          series: const [
            LineChartSeries(
              id: 'series',
              points: [ChartDataPoint(x: 1, y: 10)],
            ),
          ],
          annotations: [
            ThresholdAnnotation(
              id: 'threshold',
              axis: AnnotationAxis.y,
              value: 10,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    controller.selectSeriesIds(const ['series']);
    await tester.pump();

    final snapshot = _success(
      controller.extractDocument(
        const ChartDocumentExtractOptions(
          dataScope: ChartDataScope.selection,
          selectionProjection: ChartSelectionProjectionOptions(
            annotationProjection: ChartSelectionAnnotationProjection.omitAll,
          ),
        ),
      ),
    ).value;

    expect(snapshot.document.annotations, isEmpty);
  });

  testWidgets(
    'selection annotation bounds resolve on the referenced series axis',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: [
              const LineChartSeries(
                id: 'temperature',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                ],
              ),
              LineChartSeries(
                id: 'pressure',
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.right,
                  label: 'Pressure',
                ),
                points: const [
                  ChartDataPoint(x: 0, y: 100),
                  ChartDataPoint(x: 1, y: 200),
                ],
              ),
            ],
            annotations: [
              ThresholdAnnotation(
                id: 'temperature-outside',
                axis: AnnotationAxis.y,
                value: 150,
                seriesId: 'temperature',
              ),
              ThresholdAnnotation(
                id: 'pressure-inside',
                axis: AnnotationAxis.y,
                value: 150,
                seriesId: 'pressure',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      controller.selectSeriesIds(const ['temperature', 'pressure']);
      await tester.pump();

      final result = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      );

      expect(result.value.document.annotations.map((item) => item.id), [
        'pressure-inside',
      ]);
      expect(
        result.warnings.map((warning) => warning.path),
        contains(r'$.annotations[temperature-outside]'),
      );
    },
  );

  testWidgets(
    'implicit first-series annotations retain their original series identity',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: const [
              LineChartSeries(
                id: 'first',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                ],
              ),
              LineChartSeries(
                id: 'second',
                points: [
                  ChartDataPoint(x: 0, y: 100),
                  ChartDataPoint(x: 1, y: 200),
                ],
              ),
            ],
            annotations: [
              TrendAnnotation(
                id: 'implicit-trend',
                trendType: TrendType.linear,
              ),
              ErrorBarAnnotation(
                id: 'implicit-errors',
                values: const [ErrorBarDatum.symmetric(pointIndex: 1, y: 2)],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      controller.selectSeriesIds(const ['first']);
      await tester.pump();
      final firstSeries = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      ).value;
      expect(firstSeries.document.annotations.map((item) => item.id), [
        'implicit-trend',
        'implicit-errors',
      ]);

      controller.selectSeriesIds(const ['second']);
      await tester.pump();
      final secondSeries = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
          ),
        ),
      );
      expect(secondSeries.value.document.annotations, isEmpty);
      expect(
        secondSeries.warnings.map((warning) => warning.path),
        containsAll([
          r'$.annotations[implicit-trend]',
          r'$.annotations[implicit-errors]',
        ]),
      );
    },
  );

  testWidgets(
    'retain-contained annotation projection omits intersecting ranges',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            series: const [
              LineChartSeries(
                id: 'series',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                  ChartDataPoint(x: 2, y: 30),
                ],
              ),
            ],
            annotations: [
              RangeAnnotation(
                id: 'intersecting-range',
                startX: 0,
                endX: 2,
                startY: 10,
                endY: 30,
                seriesId: 'series',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectPoints(const [
          ChartPointRef(seriesId: 'series', pointIndex: 1),
        ], revision: revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      final result = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.selection,
            selectionProjection: ChartSelectionProjectionOptions(
              annotationProjection:
                  ChartSelectionAnnotationProjection.retainContained,
            ),
          ),
        ),
      );

      expect(result.value.document.annotations, isEmpty);
      expect(
        result.warnings.map((warning) => warning.path),
        contains(r'$.annotations[intersecting-range]'),
      );
    },
  );

  testWidgets('columnar extraction hydrates and projects to the native table', (
    tester,
  ) async {
    final bravenController = BravenChartController();
    addTearDown(bravenController.dispose);
    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: bravenController,
          series: [_series()],
        ),
      ),
    );
    await tester.pump();

    final inlineSnapshot = _success(bravenController.extractDocument()).value;
    final snapshot = _success(
      bravenController.extractDocument(
        const ChartDocumentExtractOptions(
          documentId: 'columnar-live',
          dataStorage: ChartDataStorage.inlineColumns,
        ),
      ),
    ).value;
    final payload = snapshot.document.series.single.data;
    final hydrated =
        ChartDocumentHydrator.hydrateDocument(snapshot.document)
            as ChartArtifactSuccess<HydratedChartConfiguration>;
    final table = ChartTableModel.fromDocument(snapshot.document);

    expect(payload, isA<InlineColumnarPayload>());
    expect(snapshot.document.revision, inlineSnapshot.document.revision + 1);
    expect(payload.pointCount, 1);
    expect(hydrated.value.series.single.points.single.y, 10);
    expect(table.longRows.single.yRaw, 10);
    expect(table.wideRows.single.cells['series']?.yRaw, 10);
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

    final firstBeforeSelection = _success(
      firstController.extractDocument(),
    ).value;
    firstController.selectPoint(
      const ChartPointRef(seriesId: 'first', pointIndex: 0),
      revision: firstBeforeSelection.revision,
    );

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
    expect(first.viewState?.selectedPointRefs, const [
      ChartPointRef(seriesId: 'first', pointIndex: 0),
    ]);
    expect(second.document.series.single.id, 'second');
    expect(second.viewState?.hiddenSeriesIds, isEmpty);
    expect(second.viewState?.selectedPointRefs, isEmpty);
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

ChartArtifactSuccess<T> _artifactSuccess<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}

class _UnstableLiveStreamController extends LiveStreamController {
  _UnstableLiveStreamController() : super(seriesId: 'series');

  int _readRevision = 0;

  @override
  int get committedDataRevision => _readRevision++;
}
