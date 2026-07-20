// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 14 — Cartesian value summary performance benchmark matrix
// (spec: docs/superpowers/specs/
// 2026-07-20-cartesian-value-summary-architecture-handoff.md,
// §Performance architecture, "Required benchmark matrix").
//
// Every row drives a real widget-mounted BravenChartPlus and proves its
// hot-path requirement through the ChartRenderBox debug counters
// (tracking resolver compute/publish, summary reduce, series-cache
// picture identity) — "looks smooth" is not accepted as evidence.
// Wall-clock numbers recorded in comments are environment-relative
// (debug-JIT `flutter test` on the dev machine) and the asserted
// ceilings are deliberately generous, CI-safe pathology guards in the
// style of the sibling benchmarks under test/benchmarks/.
//
// RASTER GAP (slice-0 decision D12): `flutter test` records paint
// commands but never rasterizes them, so p95 *raster* frame timing has
// no automated harness here and remains a MANUAL release gate. To run
// it manually:
//   cd example && flutter run --profile -d windows   (or -d chrome)
// open the Value Summary showcase page
// (example/lib/showcase/pages/value_summary_page.dart), enable the
// performance overlay / DevTools frame chart, hover-sweep and drag the
// panel across the presets, and confirm raster p95 stays under 16.7 ms
// per frame. This file asserts resolver/publish/reduce counts and
// build/interaction wall time only.

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One 60 Hz frame, matching the sibling group-controller benchmark.
const _frameBudget = Duration(microseconds: 16667);

void main() {
  // ==========================================================================
  // Row 1 — 5,000-point Line + Area, two series:
  // crosshair-only vs crosshair+summary. The summary must add ZERO extra
  // tracking resolutions (equal compute counts for the identical sweep) and
  // its wall-time overhead must stay within noise of the crosshair-only
  // baseline (generous <1.5x pathology ceiling).
  //
  // Measured 2026-07-20 (env-relative): baseline 90 moves in ~118-124 ms,
  // summary ~124-125 ms, ratio 1.01-1.05x; computes 90 == 90, publishes
  // 90 == 90.
  // ==========================================================================
  testWidgets(
    'row 1: 5k line+area summary adds zero resolutions and bounded overhead',
    (tester) async {
      final linePoints = _wave(5000, base: 10, amplitude: 5, omega: 0.011);
      final areaPoints = _wave(5000, base: 6, amplitude: 3, omega: 0.017);

      // One mouse pointer for the whole test (multiple gestures on the same
      // device trip the MouseTracker's add/remove pairing).
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      Future<_SweepResult> run({required bool withSummary}) async {
        await tester.pumpWidget(
          _host(
            interaction: _interaction(withSummary: withSummary),
            series: [
              LineChartSeries(id: 'speed', points: linePoints),
              AreaChartSeries(id: 'power', points: areaPoints),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        final targets = [
          for (var i = 0; i < 30; i++)
            _plotTarget(tester, renderBox, 80 + i * 160.0, 8),
        ];
        // Warm the JIT, layout, and caches with one untimed pass.
        await _sweep(tester, pointer, targets);
        return _timedSweep(tester, pointer, renderBox, targets, passes: 3);
      }

      final baseline = await run(withSummary: false);
      final summary = await run(withSummary: true);

      // Guard against a trivially-passing summary config: the panel really
      // displayed policy-resolved content during the summary sweep.
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryModel, isNotNull);
      expect(renderBox.debugValueSummaryReduceCount, greaterThan(0));
      expect(renderBox.debugValueSummaryBounds, isNot(Rect.zero));

      expect(
        summary.computeDelta,
        baseline.computeDelta,
        reason:
            'the summary must feed off the shared per-frame resolution; '
            'any extra compute means a second resolver pass per frame',
      );
      expect(
        summary.publishDelta,
        baseline.publishDelta,
        reason: 'identical sweep, identical datum changes, identical '
            'snapshot publications',
      );

      final ratio =
          summary.elapsed.inMicroseconds / baseline.elapsed.inMicroseconds;
      expect(
        ratio,
        lessThan(1.5),
        reason:
            'summary overhead must stay within noise of crosshair-only '
            '(measured ${ratio.toStringAsFixed(2)}x)',
      );
      // ignore: avoid_print
      print(
        'Row 1 (5k line+area, 90 hover moves): '
        'crosshair-only ${baseline.elapsed.inMilliseconds}ms '
        '(${baseline.computeDelta} computes) vs '
        'crosshair+summary ${summary.elapsed.inMilliseconds}ms '
        '(${summary.computeDelta} computes), '
        'ratio ${ratio.toStringAsFixed(3)}x',
      );
    },
  );

  // ==========================================================================
  // Row 2 — 50,000-point Line, fixed overlay:
  // each hover update (pointer move + frame) must complete within one
  // 16.7 ms frame at p95 in this test environment. Build/interaction time
  // only; raster is the manual D12 gate documented in the header.
  //
  // Measured 2026-07-20 (env-relative): p50 ~1.1 ms, p95 ~1.5-1.6 ms per
  // update across 120 measured datum-changing moves; 140/140 reduces.
  // ==========================================================================
  testWidgets(
    'row 2: 50k line fixed-overlay hover update stays within one frame at p95',
    (tester) async {
      final points = _wave(50000, base: 100, amplitude: 10, omega: 0.001);
      await tester.pumpWidget(
        _host(
          interaction: _interaction(),
          series: [LineChartSeries(id: 'price', points: points)],
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      // A large prime stride visits a distinct datum (and pixel) on every
      // move, so every measured update includes a full datum change:
      // resolve + publish + reduce + panel relayout + feedback repaint.
      double dataX(int i) => ((i * 4241) % 49999).toDouble();

      final reduceBefore = renderBox.debugValueSummaryReduceCount;

      // Warmup: 20 untimed updates.
      for (var i = 0; i < 20; i++) {
        await pointer.moveTo(
          _plotTarget(tester, renderBox, dataX(1000 + i), 100),
        );
        await tester.pump();
      }

      final durations = <Duration>[];
      for (var i = 0; i < 120; i++) {
        final target = _plotTarget(tester, renderBox, dataX(i), 100);
        final watch = Stopwatch()..start();
        await pointer.moveTo(target);
        await tester.pump();
        watch.stop();
        durations.add(watch.elapsed);
      }

      // Every one of the 140 datum-changing moves reduced exactly once —
      // no per-pixel or per-repaint amplification hides inside the timing.
      expect(
        renderBox.debugValueSummaryReduceCount - reduceBefore,
        140,
        reason: 'one reduce per datum change, nothing more',
      );
      expect(renderBox.debugValueSummaryModel, isNotNull);

      durations.sort();
      final p50 = durations[((durations.length - 1) * 0.50).ceil()];
      final p95 = durations[((durations.length - 1) * 0.95).ceil()];
      expect(
        p95,
        lessThan(_frameBudget),
        reason: 'a 50k-point summary update must fit one 60 Hz frame at p95',
      );
      // ignore: avoid_print
      print(
        'Row 2 (50k line, 120 hover updates): '
        'p50 ${(p50.inMicroseconds / 1000).toStringAsFixed(2)}ms, '
        'p95 ${(p95.inMicroseconds / 1000).toStringAsFixed(2)}ms per update',
      );
    },
  );

  // ==========================================================================
  // Row 3 — 2,000 Candlesticks + moving-average trend annotation:
  // a tracking sweep must not invalidate the series picture cache (identity
  // preserved across the whole sweep) and must reduce exactly once per
  // snapped-candle change.
  //
  // The sweep hovers above the candle bodies: nearest-X tracking (and the
  // summary's snapped-candle OHLC content) is Y-independent, so this is a
  // full tracking sweep. Hovering directly ON a candle body additionally
  // triggers the candlestick hover-highlight, which repaints the series
  // layer on highlight enter/exit — a PRE-EXISTING candlestick-lane
  // behavior verified byte-identical with the value summary disabled and
  // the trend annotation removed (probe 2026-07-20: invalidations at the
  // same sweep indices in all three configs). The summary itself adds
  // zero invalidations in either case.
  //
  // Measured 2026-07-20 (env-relative): 40-candle sweep in ~76 ms;
  // 40/40 computes, 40/40 publishes, 40/40 reduces, 0 cache invalidations.
  // ==========================================================================
  testWidgets(
    'row 3: 2k candlestick + MA20 tracking sweep leaves the series cache '
    'untouched and reduces once per candle',
    (tester) async {
      await tester.pumpWidget(
        _host(
          interaction: _interaction(
            content:
                const CartesianValueSummaryContent.automatic(
                  includeTrends: true,
                ),
          ),
          series: [_candles(2000)],
          annotations: [
            TrendAnnotation(
              seriesId: 'price',
              trendType: TrendType.movingAverage,
              windowSize: 20,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);

      final picture = renderBox.debugSeriesCachePicture;
      expect(picture, isNotNull);
      final reduceBefore = renderBox.debugValueSummaryReduceCount;
      final computeBefore = renderBox.debugTrackingComputeCount;
      final publishBefore = renderBox.debugTrackingPublishCount;

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      // 40 targets on distinct candle centers (50 candles apart), hovering
      // at data-Y 130 — inside the plot (the final candle's tall wick opens
      // headroom to 145) but far above every swept candle's high (~113), so
      // the sweep exercises pure nearest-X tracking without engaging the
      // pre-existing direct-body hover-highlight (see the row comment). The
      // exact-count assertions below would fail if the cursor ever left the
      // plot, so the sweep cannot pass vacuously.
      final watch = Stopwatch()..start();
      for (var i = 0; i < 40; i++) {
        await pointer.moveTo(
          _plotTarget(tester, renderBox, (i * 50).toDouble(), 130),
        );
        await tester.pump();
      }
      watch.stop();

      // Zero series-cache invalidations across the whole tracking sweep:
      // the identical Picture instance survives every frame.
      expect(renderBox.debugSeriesCachePicture, same(picture));
      // Exactly one reduce (and one compute/publish) per snapped-candle
      // change — datum-identity suppression leaves nothing extra.
      expect(renderBox.debugValueSummaryReduceCount - reduceBefore, 40);
      expect(renderBox.debugTrackingComputeCount - computeBefore, 40);
      expect(renderBox.debugTrackingPublishCount - publishBefore, 40);
      expect(renderBox.debugValueSummaryModel, isNotNull);
      // ignore: avoid_print
      print(
        'Row 3 (2k candles + MA20, 40-candle sweep): '
        '${watch.elapsedMilliseconds}ms, 40 reduces, '
        '0 series-cache invalidations',
      );
    },
  );

  // ==========================================================================
  // Row 4 — dense Scatter (10k points):
  // the summary must reuse Scatter's final two-dimensional hit. Proof: the
  // tracking compute count for a hover sweep with the summary enabled
  // EQUALS the crosshair-only baseline for the same sweep — no second O(N)
  // nearest-point scan exists anywhere in the summary path.
  //
  // Measured 2026-07-20 (env-relative): 50 moves — 50 computes in both
  // configs; baseline ~256 ms vs summary ~262-274 ms.
  // ==========================================================================
  testWidgets(
    'row 4: 10k scatter summary adds no second nearest-point scan',
    (tester) async {
      final points = [
        for (var i = 0; i < 10000; i++)
          ChartDataPoint(
            x: (i * 0.6180339887) % 100 * 5,
            y: 50 + 45 * math.sin(i * 2.399963),
          ),
      ];

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      Future<_SweepResult> run({required bool withSummary}) async {
        await tester.pumpWidget(
          _host(
            interaction: _interaction(withSummary: withSummary),
            series: [ScatterChartSeries(id: 'cloud', points: points)],
          ),
        );
        await tester.pumpAndSettle();
        final renderBox = _renderBox(tester);
        final targets = [
          for (var i = 0; i < 25; i++)
            _plotTarget(
              tester,
              renderBox,
              20.0 * i + 10,
              50 + 40 * math.sin(i * 1.3),
            ),
        ];
        await _sweep(tester, pointer, targets);
        return _timedSweep(tester, pointer, renderBox, targets, passes: 2);
      }

      final baseline = await run(withSummary: false);
      final summary = await run(withSummary: true);

      final renderBox = _renderBox(tester);
      // The summary displayed the very snapshot the crosshair resolved —
      // one shared resolution, one shared 2D hit.
      expect(renderBox.debugValueSummaryModel, isNotNull);
      expect(
        renderBox.debugValueSummarySnapshot,
        same(renderBox.debugTrackingSnapshot),
      );
      expect(
        summary.computeDelta,
        baseline.computeDelta,
        reason:
            'summary-enabled scatter tracking must not add a second O(N) '
            'nearest-point scan for the same sweep',
      );
      // ignore: avoid_print
      print(
        'Row 4 (10k scatter, 50 hover moves): '
        'crosshair-only ${baseline.computeDelta} computes '
        '(${baseline.elapsed.inMilliseconds}ms) vs '
        'crosshair+summary ${summary.computeDelta} computes '
        '(${summary.elapsed.inMilliseconds}ms)',
      );
    },
  );

  // ==========================================================================
  // Row 5 — three synchronized charts:
  // driving the shared cursor from one participant must produce exactly one
  // group broadcast per step and exactly one local tracking resolution per
  // participant per step — no broadcast amplification, no cross-chart row
  // allocation.
  //
  // Measured 2026-07-20 (env-relative): 8 cursor steps -> 8 broadcasts,
  // computes 8/8/8, in ~21-22 ms.
  // ==========================================================================
  testWidgets(
    'row 5: three synchronized charts resolve once per participant per '
    'cursor step',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);

      // A silent probe participant counts every shared-cursor broadcast the
      // group actually emits.
      var broadcasts = 0;
      final probe = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) => broadcasts++,
        onViewportChanged: (_) {},
      );
      addTearDown(probe.dispose);

      await tester.pumpWidget(_synchronizedHost(group));
      await tester.pumpAndSettle();

      final renderElements = _chartRenderFinder().evaluate().toList();
      expect(renderElements, hasLength(3));
      final charts = [
        for (final element in renderElements)
          element.renderObject! as ChartRenderBox,
      ];
      final firstFinder = find.byElementPredicate(
        (element) => element == renderElements.first,
      );

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);

      Offset chartOneTarget(double dataX) =>
          tester.getTopLeft(firstFinder) +
          charts.first.plotToWidget(
            charts.first.transform!.dataToPlot(
              dataX,
              (charts.first.transform!.dataYMin +
                      charts.first.transform!.dataYMax) /
                  2,
            ),
          );

      const steps = [0.6, 1.8, 3.0, 4.2, 5.4, 6.6, 7.8, 9.0];
      final computeBefore = [
        for (final chart in charts) chart.debugTrackingComputeCount,
      ];
      final broadcastsBefore = broadcasts;

      final watch = Stopwatch()..start();
      for (final dataX in steps) {
        await pointer.moveTo(chartOneTarget(dataX));
        await tester.pump();
      }
      watch.stop();

      // One broadcast per cursor step — receivers never re-publish.
      expect(
        broadcasts - broadcastsBefore,
        steps.length,
        reason: 'one group broadcast per cursor step, no amplification',
      );
      // One local resolution per participant per step: the driving chart
      // resolves its own pointer once, each receiver resolves the
      // synchronized cursor once, and the summary rides the same snapshot.
      for (var i = 0; i < charts.length; i++) {
        expect(
          charts[i].debugTrackingComputeCount - computeBefore[i],
          steps.length,
          reason: 'chart $i must resolve exactly once per cursor step',
        );
        expect(charts[i].debugValueSummaryModel, isNotNull);
      }
      // ignore: avoid_print
      print(
        'Row 5 (3 synchronized charts, ${steps.length} cursor steps): '
        '${broadcasts - broadcastsBefore} broadcasts, computes '
        '${[for (var i = 0; i < charts.length; i++) charts[i].debugTrackingComputeCount - computeBefore[i]].join('/')}, '
        '${watch.elapsedMilliseconds}ms',
      );
    },
  );

  // ==========================================================================
  // Row 6 — draggable annotation summary:
  // during a drag the resolution pipeline is suspended (reduce and compute
  // counters frozen, snapshot/model identity preserved), the panel repaints
  // through the feedback layer only (series picture identity preserved),
  // and release commits exactly one placement.
  //
  // Measured 2026-07-20 (env-relative): 6-move drag in ~6 ms, counters
  // frozen throughout, 1 commit, 0 series-cache invalidations.
  // ==========================================================================
  testWidgets(
    'row 6: dragging the summary freezes resolution and commits once',
    (tester) async {
      final placements = <ChartOverlayPlacement>[];
      await tester.pumpWidget(
        _host(
          interaction: _interaction(
            presentation: const CartesianValueSummaryPresentation.annotation(
              draggable: true,
            ),
            onPlacementChanged: placements.add,
          ),
          series: [
            LineChartSeries(
              id: 'speed',
              points: _wave(1000, base: 10, amplitude: 5, omega: 0.02),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final renderBox = _renderBox(tester);
      expect(renderBox.debugValueSummaryBounds.topLeft, const Offset(12, 12));

      // Establish live tracking away from the panel.
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(_plotTarget(tester, renderBox, 600, 10));
      await tester.pump();
      expect(
        renderBox.debugValueSummarySnapshot?.origin,
        CartesianTrackingOrigin.pointer,
      );

      // Move onto the panel and let the deferred hover hit test flip the
      // cursor to `move` (50ms throttle). That cursor setState triggers one
      // widget rebuild which regenerates the series picture once — capture
      // identities after it settles so the drag itself is proven
      // invalidation-free.
      await pointer.moveTo(_panelCenter(tester, renderBox));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      final frozenSnapshot = renderBox.debugValueSummarySnapshot;
      final frozenModel = renderBox.debugValueSummaryModel;
      final reduceCount = renderBox.debugValueSummaryReduceCount;
      final computeCount = renderBox.debugTrackingComputeCount;
      final seriesPicture = renderBox.debugSeriesCachePicture;
      expect(seriesPicture, isNotNull);

      // Drag: N move events, each pumped as its own frame.
      const moveEvents = 6;
      await pointer.down(_panelCenter(tester, renderBox));
      final watch = Stopwatch()..start();
      for (var i = 0; i < moveEvents; i++) {
        await pointer.moveBy(const Offset(12, 8));
        await tester.pump();
        // Frozen on every intermediate frame, not just at the end.
        expect(
          renderBox.debugValueSummaryReduceCount,
          reduceCount,
          reason: 'reduce count must stay frozen during the drag',
        );
        expect(
          renderBox.debugTrackingComputeCount,
          computeCount,
          reason: 'tracking compute must stay suspended during the drag',
        );
      }
      watch.stop();

      // The displayed content never changed identity, and the drag repainted
      // only the feedback layer: the cached series picture instance survived
      // the whole gesture.
      expect(renderBox.debugValueSummarySnapshot, same(frozenSnapshot));
      expect(renderBox.debugValueSummaryModel, same(frozenModel));
      expect(renderBox.debugSeriesCachePicture, same(seriesPicture));
      // The panel really moved with the pointer (continuous paint).
      expect(
        renderBox.debugValueSummaryBounds.topLeft,
        const Offset(12 + 12.0 * moveEvents, 12 + 8.0 * moveEvents),
      );
      expect(placements, isEmpty);

      await pointer.up();
      await tester.pump();

      // Exactly one committed placement on release.
      expect(placements, hasLength(1));
      expect(
        placements.single.offset,
        const Offset(12 + 12.0 * moveEvents, 12 + 8.0 * moveEvents),
      );
      expect(renderBox.debugSeriesCachePicture, same(seriesPicture));
      // ignore: avoid_print
      print(
        'Row 6 (draggable summary, $moveEvents-move drag): '
        '${watch.elapsedMilliseconds}ms, counters frozen, '
        '${placements.length} commit, 0 series-cache invalidations',
      );
    },
  );
}

// ============================================================================
// Harness helpers
// ============================================================================

/// Compute/publish deltas and wall time of one timed hover sweep.
class _SweepResult {
  const _SweepResult(this.computeDelta, this.publishDelta, this.elapsed);

  final int computeDelta;
  final int publishDelta;
  final Duration elapsed;
}

/// Moves the pointer through [targets], pumping one frame per move.
Future<void> _sweep(
  WidgetTester tester,
  TestGesture pointer,
  List<Offset> targets,
) async {
  for (final target in targets) {
    await pointer.moveTo(target);
    await tester.pump();
  }
}

/// Runs [passes] hover passes over [targets] under a Stopwatch and returns
/// the tracking compute/publish deltas alongside the elapsed wall time.
Future<_SweepResult> _timedSweep(
  WidgetTester tester,
  TestGesture pointer,
  ChartRenderBox renderBox,
  List<Offset> targets, {
  required int passes,
}) async {
  final computeBefore = renderBox.debugTrackingComputeCount;
  final publishBefore = renderBox.debugTrackingPublishCount;
  final watch = Stopwatch()..start();
  for (var pass = 0; pass < passes; pass++) {
    await _sweep(tester, pointer, targets);
  }
  watch.stop();
  return _SweepResult(
    renderBox.debugTrackingComputeCount - computeBefore,
    renderBox.debugTrackingPublishCount - publishBefore,
    watch.elapsed,
  );
}

/// Sine-wave line data with a deterministic shape.
List<ChartDataPoint> _wave(
  int count, {
  required double base,
  required double amplitude,
  required double omega,
}) => [
  for (var i = 0; i < count; i++)
    ChartDataPoint(x: i.toDouble(), y: base + amplitude * math.sin(i * omega)),
];

/// A deterministic 2,000-candle price series around 100.
///
/// The final candle (x = count-1, never a sweep target) carries a tall
/// upper wick to 145 so the Y axis opens headroom above the ~113 highs of
/// every other candle — the row-3 sweep hovers in that headroom to track
/// candles without sitting on their bodies.
CandlestickChartSeries _candles(int count) {
  return CandlestickChartSeries(
    id: 'price',
    points: [
      for (var i = 0; i < count; i++)
        () {
          final base = 100 + 10 * math.sin(i * 0.01);
          final close = base + 2 * math.sin(i * 0.13);
          return CandlestickDataPoint(
            x: i.toDouble(),
            open: base,
            high: i == count - 1 ? 145 : math.max(base, close) + 1,
            low: math.min(base, close) - 1,
            close: close,
          );
        }(),
    ],
  );
}

/// Tracking crosshair (datum-snapped) with or without the value summary.
InteractionConfig _interaction({
  bool withSummary = true,
  CartesianValueSummaryContent content =
      const CartesianValueSummaryContent.automatic(),
  CartesianValueSummaryPresentation presentation =
      const CartesianValueSummaryPresentation.overlay(),
  ValueChanged<ChartOverlayPlacement>? onPlacementChanged,
}) {
  return InteractionConfig(
    crosshair: const CrosshairConfig(
      displayMode: CrosshairDisplayMode.tracking,
      // Snap to actual data points so one hover position produces one
      // stable snapshot identity.
      interpolateValues: false,
    ),
    valueSummary: withSummary
        ? CartesianValueSummaryConfig(
            enabled: true,
            content: content,
            presentation: presentation,
            onPlacementChanged: onPlacementChanged,
          )
        : const CartesianValueSummaryConfig(),
  );
}

Widget _host({
  required InteractionConfig interaction,
  required List<ChartSeries> series,
  List<ChartAnnotation> annotations = const [],
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 760,
          height: 340,
          child: BravenChartPlus(
            showLegend: false,
            interactionConfig: interaction,
            annotations: annotations,
            series: series,
          ),
        ),
      ),
    ),
  );
}

/// Three synchronized line charts sharing one interaction group, each with
/// the value summary enabled.
Widget _synchronizedHost(ChartInteractionGroupController group) {
  Widget chart(String id, double base) => SizedBox(
    width: 640,
    height: 180,
    child: BravenChartPlus(
      interactionGroupController: group,
      showLegend: false,
      interactionConfig: _interaction(),
      series: [
        LineChartSeries(
          id: id,
          points: [
            for (var i = 0; i <= 11; i++)
              ChartDataPoint(
                x: i.toDouble(),
                y: base + 3 * math.sin(i * 0.9),
              ),
          ],
        ),
      ],
    ),
  );

  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chart('speed', 10),
            chart('power', 200),
            chart('cadence', 90),
          ],
        ),
      ),
    ),
  );
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);

ChartRenderBox _renderBox(WidgetTester tester) =>
    _chartRenderFinder().evaluate().single.renderObject! as ChartRenderBox;

Offset _plotTarget(
  WidgetTester tester,
  ChartRenderBox renderBox,
  double dataX,
  double dataY,
) {
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(renderBox.transform!.dataToPlot(dataX, dataY));
}

/// Widget-space center of the currently painted summary panel.
Offset _panelCenter(WidgetTester tester, ChartRenderBox renderBox) {
  final bounds = renderBox.debugValueSummaryBounds;
  assert(bounds != Rect.zero, 'value summary panel is not painted');
  return tester.getTopLeft(find.byType(BravenChartPlus)) +
      renderBox.plotToWidget(bounds.center);
}
