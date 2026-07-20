import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/data_point_label_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesElement scatter geometry', () {
    test('does not hit the invisible segment between scatter points', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'scatter',
          points: [ChartDataPoint(x: 0, y: 0), ChartDataPoint(x: 10, y: 10)],
          markerRadius: 5,
        ),
        transform: _transform(),
      );

      expect(element.hitTest(const Offset(50, 50)), isFalse);
      expect(element.hitTest(const Offset(3, 97)), isTrue);
    });

    test('uses the effective per-point marker radius for hit testing', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'scatter',
          points: [
            ChartDataPoint(x: 5, y: 5, pointStyle: PointStyle(size: 18)),
          ],
          markerRadius: 4,
        ),
        transform: _transform(),
      );

      expect(element.hitTest(const Offset(67, 50)), isTrue);
      expect(element.dataHitAt(const Offset(67, 50))?.pointIndex, 0);
      expect(element.hitTest(const Offset(75, 50)), isFalse);
    });

    test('invalid-only data has safe bounds and no interactions', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'invalid',
          points: [
            ChartDataPoint(x: double.nan, y: 2),
            ChartDataPoint(x: 3, y: double.infinity),
          ],
        ),
        transform: _transform(),
      );

      expect(element.bounds, Rect.zero);
      expect(element.hitTest(const Offset(50, 50)), isFalse);
      expect(element.dataHitAt(const Offset(50, 50)), isNull);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => element.paint(canvas, const Size(100, 100)),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('duplicate points resolve to the first stable source index', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'duplicates',
          points: [ChartDataPoint(x: 5, y: 5), ChartDataPoint(x: 5, y: 5)],
        ),
        transform: _transform(),
      );

      expect(element.dataHitAt(const Offset(50, 50))?.pointIndex, 0);
    });

    test(
      'cluster mode aggregates nearby markers and retains raw identities',
      () {
        final element = SeriesElement(
          series: const ScatterChartSeries(
            id: 'clustered',
            name: 'Clustered cohort',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 0.1, y: 0.1),
              ChartDataPoint(x: 10, y: 10),
            ],
            renderMode: ScatterRenderMode.clusters,
            clusterConfig: ScatterClusterConfig(
              cellSize: 40,
              minimumPointCount: 2,
              minimumRadius: 8,
              maximumRadius: 20,
            ),
          ),
          transform: _transform(),
        );

        expect(element.visibleScatterGeometryCount, 3);
        expect(element.visibleScatterRenderedMarkerCount, 2);
        expect(element.visibleScatterClusteredPointCount, 2);

        final hit = element.dataHitAt(const Offset(0.5, 99.5));
        expect(hit, isNotNull);
        expect(hit!.pointIndex, 0);
        expect(hit.sourcePointIndices, [0, 1]);
        expect(hit.category, '2 observations');
        expect(hit.formattedXValue, '0.05');
        expect(hit.formattedValue, '0.05');
        expect(hit.semanticLabel, contains('2 source points'));

        final recorder = PictureRecorder();
        expect(
          () => element.paint(Canvas(recorder), const Size(100, 100)),
          returnsNormally,
        );
        recorder.endRecording().dispose();
      },
    );

    test('cluster hit comparisons remain bounded by screen-space cells', () {
      final points = [
        for (var index = 0; index < 10000; index++)
          ChartDataPoint(
            x: (index % 100).toDouble() / 10,
            y: (index ~/ 100).toDouble() / 10,
          ),
      ];
      final element = SeriesElement(
        series: ScatterChartSeries(
          id: 'dense-clusters',
          points: points,
          renderMode: ScatterRenderMode.clusters,
          clusterConfig: const ScatterClusterConfig(cellSize: 32),
        ),
        transform: _transform(),
      );

      expect(element.visibleScatterRenderedMarkerCount, lessThan(30));
      expect(element.dataHitAt(const Offset(50, 50)), isNotNull);
      expect(element.scatterHitComparisonCount, lessThan(20));
    });

    for (final mode in [
      ScatterRenderMode.rectangularBins,
      ScatterRenderMode.hexbin,
    ]) {
      test('${mode.name} aggregates, paints, and retains raw identities', () {
        final element = SeriesElement(
          series: ScatterChartSeries(
            id: '${mode.name}-series',
            name: 'Dense observations',
            points: const [
              ChartDataPoint(x: 1, y: 5),
              ChartDataPoint(x: 1.1, y: 5.1),
              ChartDataPoint(x: 8, y: 8),
            ],
            color: const Color(0xFF0F8FA8),
            renderMode: mode,
            binConfig: const ScatterBinConfig(
              cellSize: 32,
              aggregate: ScatterBinAggregate.mean,
              valueSource: ScatterBinValueSource.y,
              showLabels: true,
              labelMinimumPointCount: 2,
            ),
          ),
          transform: _transform(),
        );

        expect(element.visibleScatterGeometryCount, 3);
        expect(element.visibleScatterRenderedMarkerCount, 2);
        expect(element.visibleScatterBinnedPointCount, 3);

        final first = element.dataHitForPointIndex(1);
        expect(first, isNotNull);
        expect(first!.sourcePointIndices, [0, 1]);
        expect(first.category, contains('bin'));
        expect(first.aggregateValue, closeTo(5.05, 0.0001));
        expect(first.aggregateLabel, 'Mean Y');
        expect(first.formattedAggregateValue, '5.05');
        expect(first.aggregateSampleCount, 2);
        expect(first.semanticLabel, contains('2 source points'));
        expect(first.semanticLabel, contains('Mean Y 5.05'));
        expect(element.dataHitAt(first.plotPosition), isNotNull);

        final recorder = PictureRecorder();
        expect(
          () => element.paint(Canvas(recorder), const Size(100, 100)),
          returnsNormally,
        );
        recorder.endRecording().dispose();
      });
    }

    test('density mode paints contours and exposes honest aggregate hits', () {
      final element = SeriesElement(
        series: ScatterChartSeries(
          id: 'density-series',
          name: 'Pickup demand',
          color: const Color(0xFF0F8FA8),
          points: [
            for (var index = 0; index < 30; index++)
              ChartDataPoint(
                x: 4.6 + (index % 6) * 0.14,
                y: 4.6 + (index ~/ 6) * 0.14,
              ),
          ],
          renderMode: ScatterRenderMode.density,
          densityConfig: const ScatterDensityConfig(
            gridCellSize: 5,
            bandwidth: 14,
            contourCount: 5,
            minimumDensity: 0.1,
          ),
        ),
        transform: _transform(),
      );

      expect(element.visibleScatterGeometryCount, 30);
      expect(element.visibleScatterRenderedMarkerCount, inInclusiveRange(1, 5));

      final hit = element.dataHitAt(const Offset(50, 50));
      expect(hit, isNotNull);
      expect(hit!.sourcePointIndices.length, greaterThan(1));
      expect(hit.category, contains('density region'));
      expect(hit.aggregateLabel, 'Relative density');
      expect(hit.aggregateValue, inInclusiveRange(0.1, 1));
      expect(hit.formattedAggregateValue, endsWith('%'));
      expect(hit.aggregateSampleCount, hit.sourcePointIndices.length);
      expect(hit.semanticLabel, contains('Relative density'));
      expect(hit.semanticBounds.contains(const Offset(50, 50)), isTrue);
      expect(element.dataHitAt(const Offset(98, 2)), isNull);

      final sourceHit = element.dataHitForPointIndex(12);
      expect(sourceHit, isNotNull);
      expect(sourceHit!.category, contains('density region'));

      final recorder = PictureRecorder();
      expect(
        () => element.paint(Canvas(recorder), const Size(100, 100)),
        returnsNormally,
      );
      recorder.endRecording().dispose();
    });

    test('cluster layout reveals raw observations as the viewport zooms', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'zooming-clusters',
          points: [ChartDataPoint(x: 1, y: 5), ChartDataPoint(x: 1.5, y: 5)],
          renderMode: ScatterRenderMode.clusters,
          clusterConfig: ScatterClusterConfig(cellSize: 40),
        ),
        transform: _transform(),
      );

      expect(element.visibleScatterRenderedMarkerCount, 1);
      expect(element.visibleScatterClusteredPointCount, 2);

      element.updateTransform(
        const ChartTransform(
          dataXMin: 0.8,
          dataXMax: 1.7,
          dataYMin: 4.5,
          dataYMax: 5.5,
          plotWidth: 100,
          plotHeight: 100,
        ),
      );

      expect(element.visibleScatterRenderedMarkerCount, 2);
      expect(element.visibleScatterClusteredPointCount, 0);
    });

    test('jitter is deterministic, seeded, and stable through zoom', () {
      const series = ScatterChartSeries(
        id: 'jittered-responses',
        points: [
          ChartDataPoint(x: 5, y: 5),
          ChartDataPoint(x: 5, y: 5),
          ChartDataPoint(x: 5, y: 5),
        ],
        markerRadius: 2,
        jitter: ScatterJitterConfig(xAmplitude: 18, yAmplitude: 12, seed: 42),
      );
      final first = SeriesElement(series: series, transform: _transform());
      final second = SeriesElement(series: series, transform: _transform());
      final firstCenters = [
        for (var index = 0; index < series.points.length; index++)
          first.scatterGeometryForPoint(index)!.center,
      ];
      final secondCenters = [
        for (var index = 0; index < series.points.length; index++)
          second.scatterGeometryForPoint(index)!.center,
      ];

      expect(firstCenters.toSet(), hasLength(3));
      expect(secondCenters, firstCenters);
      expect(
        firstCenters.map((center) => center.dx).reduce(math.max) -
            firstCenters.map((center) => center.dx).reduce(math.min),
        greaterThan(9),
      );
      expect(
        firstCenters.map((center) => center.dy).reduce(math.max) -
            firstCenters.map((center) => center.dy).reduce(math.min),
        greaterThan(6),
      );
      expect(
        first.dataHitAt(firstCenters.first)?.plotPosition,
        firstCenters.first,
      );

      final reseeded = SeriesElement(
        series: series.copyWith(
          jitter: const ScatterJitterConfig(
            xAmplitude: 18,
            yAmplitude: 12,
            seed: 43,
          ),
        ),
        transform: _transform(),
      );
      expect(
        reseeded.scatterGeometryForPoint(0)!.center,
        isNot(firstCenters[0]),
      );

      const zoomed = ChartTransform(
        dataXMin: 2.5,
        dataXMax: 7.5,
        dataYMin: 2.5,
        dataYMax: 7.5,
        plotWidth: 100,
        plotHeight: 100,
      );
      final rawBefore = _transform().dataToPlot(5, 5);
      final offsetBefore = firstCenters.first - rawBefore;
      first.updateTransform(zoomed);
      final rawAfter = zoomed.dataToPlot(5, 5);
      final offsetAfter = first.scatterGeometryForPoint(0)!.center - rawAfter;
      expect(offsetAfter, offsetBefore);
    });

    test('point labels honor content, marker gap, and explicit offsets', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'label-offset',
          points: [ChartDataPoint(x: 5, y: 5, label: 'A')],
          markerRadius: 5,
          dataPointLabels: DataPointLabelConfig(
            show: true,
            content: DataPointLabelContent.pointLabel,
            position: DataPointLabelPosition.right,
            markerGap: 6,
            offsetX: 8,
            offsetY: 4,
          ),
        ),
        transform: _transform(),
      );
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(100, 100));
      recorder.endRecording();

      final rect = element.visibleScatterLabelBounds.single;
      expect(rect.left, greaterThanOrEqualTo(69));
      expect(rect.center.dy, closeTo(54, 0.01));
    });

    test('reposition coordinates label collisions across scatter series', () {
      const labels = DataPointLabelConfig(
        show: true,
        content: DataPointLabelContent.pointLabel,
        position: DataPointLabelPosition.above,
        collisionPolicy: DataPointLabelCollisionPolicy.reposition,
        collisionPadding: 2,
      );
      final first = SeriesElement(
        series: const ScatterChartSeries(
          id: 'labels-a',
          points: [ChartDataPoint(x: 5, y: 5, label: 'Alpha')],
          dataPointLabels: labels,
        ),
        transform: _transform(),
      );
      final second = SeriesElement(
        series: const ScatterChartSeries(
          id: 'labels-b',
          points: [ChartDataPoint(x: 5, y: 5, label: 'Beta')],
          dataPointLabels: labels,
        ),
        transform: _transform(),
      );
      final coordinator = DataPointLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      first.setDataPointLabelLayoutCoordinator(coordinator);
      second.setDataPointLabelLayoutCoordinator(coordinator);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      first.paint(canvas, const Size(100, 100));
      second.paint(canvas, const Size(100, 100));
      recorder.endRecording();

      final firstRect = first.visibleScatterLabelBounds.single;
      final secondRect = second.visibleScatterLabelBounds.single;
      expect(firstRect.overlaps(secondRect), isFalse);
      expect(coordinator.occupiedBounds, hasLength(2));
    });

    test('hide collision policy omits an occupied point label', () {
      const labels = DataPointLabelConfig(
        show: true,
        content: DataPointLabelContent.pointLabel,
        collisionPolicy: DataPointLabelCollisionPolicy.hide,
      );
      final coordinator = DataPointLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      final elements = [
        for (final id in ['first', 'second'])
          SeriesElement(
            series: ScatterChartSeries(
              id: id,
              points: [ChartDataPoint(x: 5, y: 5, label: id)],
              dataPointLabels: labels,
            ),
            transform: _transform(),
          )..setDataPointLabelLayoutCoordinator(coordinator),
      ];
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (final element in elements) {
        element.paint(canvas, const Size(100, 100));
      }
      recorder.endRecording();

      expect(elements.first.visibleScatterLabelBounds, hasLength(1));
      expect(elements.last.visibleScatterLabelBounds, isEmpty);
    });

    test('series marker radius takes precedence over ambient theme size', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'radius-precedence',
          points: [ChartDataPoint(x: 5, y: 5)],
          markerRadius: 2,
        ),
        transform: _transform(),
        seriesTheme: SeriesTheme.highContrast,
      );

      // Radius 2 plus the standard 4px interaction slop does not reach 7px.
      // The old theme-first geometry used the theme's 10px marker and hit.
      expect(element.hitTest(const Offset(57, 50)), isFalse);
      expect(element.hitTest(const Offset(55, 50)), isTrue);
    });

    test('uniform batched markers preserve the configured radius', () async {
      final smallPixels = await _paintedPixelCount(markerRadius: 2);
      final largePixels = await _paintedPixelCount(markerRadius: 9);

      expect(smallPixels, greaterThan(0));
      expect(largePixels, greaterThan(smallPixels * 8));
    });

    test('non-circular markers use their visible silhouette for hits', () {
      final square = SeriesElement(
        series: const ScatterChartSeries(
          id: 'square',
          points: [ChartDataPoint(x: 5, y: 5)],
          markerRadius: 5,
          markerShape: SeriesMarkerShape.square,
        ),
        transform: _transform(),
      );
      final circle = SeriesElement(
        series: const ScatterChartSeries(
          id: 'circle',
          points: [ChartDataPoint(x: 5, y: 5)],
          markerRadius: 5,
        ),
        transform: _transform(),
      );

      expect(square.hitTest(const Offset(58, 58)), isTrue);
      expect(circle.hitTest(const Offset(58, 58)), isFalse);
    });

    test('per-point marker shape overrides series geometry and hits', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'point-shape',
          points: [
            ChartDataPoint(
              x: 5,
              y: 5,
              pointStyle: PointStyle(
                scatterMarkerShape: SeriesMarkerShape.square,
              ),
            ),
          ],
          markerRadius: 5,
          markerShape: SeriesMarkerShape.circle,
        ),
        transform: _transform(),
      );

      expect(element.hitTest(const Offset(58, 58)), isTrue);
    });

    test(
      'categorical shape and color resolve below explicit point styling',
      () {
        final element = SeriesElement(
          series: const ScatterChartSeries(
            id: 'category',
            points: [ChartDataPoint(x: 5, y: 5, categoryValue: 'hybrid')],
            color: Color(0xFF111111),
            markerRadius: 5,
            markerShape: SeriesMarkerShape.circle,
            categoryEncoding: ScatterCategoryEncoding(
              label: 'Powertrain',
              categories: [
                ScatterCategoryStyle(
                  key: 'hybrid',
                  color: Color(0xFF16A34A),
                  shape: SeriesMarkerShape.square,
                ),
              ],
            ),
          ),
          transform: _transform(),
        );

        expect(element.hitTest(const Offset(58, 58)), isTrue);
        final hit = element.dataHitAt(const Offset(50, 50));
        expect(hit?.markerColor, const Color(0xFF16A34A));
        expect(hit?.categoryValue, 'hybrid');
        expect(hit?.categoryLabel, 'Powertrain');
      },
    );

    test('marker geometry participates in series equality', () {
      const source = ScatterChartSeries(
        id: 'equality',
        points: [ChartDataPoint(x: 1, y: 2)],
      );

      expect(source.copyWith(markerRadius: 9), isNot(source));
      expect(
        source.copyWith(markerShape: SeriesMarkerShape.star),
        isNot(source),
      );
      expect(source.copyWith(), source);
    });

    test('advanced dimensions and point overrides drive precise hits', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'styled-hit',
          points: [
            ChartDataPoint(
              x: 5,
              y: 5,
              pointStyle: PointStyle(
                scatterMarkerStyle: ScatterMarkerStyle(
                  width: 24,
                  height: 6,
                  rotationDegrees: 90,
                ),
              ),
            ),
          ],
          markerShape: SeriesMarkerShape.square,
          markerStyle: ScatterMarkerStyle(width: 8, height: 8),
        ),
        transform: _transform(),
      );

      expect(element.hitTest(const Offset(50, 60)), isTrue);
      expect(element.hitTest(const Offset(60, 50)), isFalse);
    });

    test('advanced marker style participates in series equality', () {
      const source = ScatterChartSeries(
        id: 'style-equality',
        points: [ChartDataPoint(x: 1, y: 2)],
        markerStyle: ScatterMarkerStyle(opacity: 0.8),
      );

      expect(
        source.copyWith(markerStyle: const ScatterMarkerStyle(opacity: 0.5)),
        isNot(source),
      );
      expect(source.copyWith(), source);
    });

    test('interaction style participates in series equality', () {
      const source = ScatterChartSeries(
        id: 'interaction-equality',
        points: [ChartDataPoint(x: 1, y: 2)],
      );

      expect(
        source.copyWith(
          interactionStyle: const ScatterInteractionStyle(hoverScale: 1.6),
        ),
        isNot(source),
      );
      expect(source.copyWith(), source);
    });

    test(
      'interaction style copyWith preserves and clears inherited colors',
      () {
        const source = ScatterInteractionStyle(
          hoverColor: Color(0xFF0F172A),
          selectionColor: Color(0xFF4F46E5),
          focusColor: Color(0xFFF59E0B),
          selectionScale: 1.4,
          dimmedOpacity: 0.24,
        );

        expect(
          source.copyWith(selectionScale: 1.8, dimmedOpacity: 0.4),
          const ScatterInteractionStyle(
            hoverColor: Color(0xFF0F172A),
            selectionColor: Color(0xFF4F46E5),
            focusColor: Color(0xFFF59E0B),
            selectionScale: 1.8,
            dimmedOpacity: 0.4,
          ),
        );
        expect(
          source.copyWith(
            clearHoverColor: true,
            clearSelectionColor: true,
            clearFocusColor: true,
          ),
          const ScatterInteractionStyle(
            selectionScale: 1.4,
            dimmedOpacity: 0.24,
          ),
        );
      },
    );

    test('bubble magnitude maps linearly to marker area', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'bubble-area',
          points: [
            ChartDataPoint(x: 2, y: 5, magnitude: 0),
            ChartDataPoint(x: 5, y: 5, magnitude: 25),
            ChartDataPoint(x: 8, y: 5, magnitude: 100),
          ],
          sizeEncoding: ScatterSizeEncoding(
            minimumRadius: 4,
            maximumRadius: 20,
            maximumValue: 100,
          ),
        ),
        transform: _transform(),
      );

      expect(element.scatterGeometryForPoint(0)?.width, 8);
      expect(element.scatterGeometryForPoint(1)?.width, closeTo(21.16, 0.01));
      expect(element.scatterGeometryForPoint(2)?.width, 40);
    });

    test('continuous color encoding clamps and preserves point overrides', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'continuous-color',
          points: [
            ChartDataPoint(x: 1, y: 5, colorValue: -10),
            ChartDataPoint(x: 3, y: 5, colorValue: 50),
            ChartDataPoint(
              x: 5,
              y: 5,
              colorValue: 100,
              pointStyle: PointStyle(color: Color(0xFF123456)),
            ),
            ChartDataPoint(x: 7, y: 5, colorValue: double.nan),
          ],
          color: Color(0xFF999999),
          colorEncoding: ScatterColorEncoding(
            colors: [Color(0xFF0000FF), Color(0xFFFF0000)],
            minimumValue: 0,
            maximumValue: 100,
            label: 'Temperature',
            unit: 'C',
          ),
        ),
        transform: _transform(),
      );

      expect(
        element.dataHitForPointIndex(0)?.markerColor,
        const Color(0xFF0000FF),
      );
      expect(
        element.dataHitForPointIndex(1)?.markerColor,
        Color.lerp(const Color(0xFF0000FF), const Color(0xFFFF0000), 0.5),
      );
      expect(
        element.dataHitForPointIndex(2)?.markerColor,
        const Color(0xFF123456),
      );
      expect(element.dataHitForPointIndex(3)?.markerColor, isNull);
      expect(element.dataHitForPointIndex(1)?.formattedColorValue, '50 C');
      expect(element.visibleScatterPointIndices, [0, 1, 2, 3]);
    });

    test('piecewise color thresholds include equality in the higher band', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'piecewise-color',
          points: [
            ChartDataPoint(x: 1, y: 5, colorValue: 34.9),
            ChartDataPoint(x: 2, y: 5, colorValue: 35),
            ChartDataPoint(x: 3, y: 5, colorValue: 60),
            ChartDataPoint(x: 4, y: 5, colorValue: 80),
          ],
          colorEncoding: ScatterColorEncoding(
            colors: [
              Color(0xFF16A34A),
              Color(0xFFFACC15),
              Color(0xFFF97316),
              Color(0xFFDC2626),
            ],
            scaleType: ScatterColorScaleType.piecewise,
            thresholds: [35, 60, 80],
            bandLabels: ['Normal', 'Monitor', 'Warning', 'Critical'],
            label: 'Risk score',
          ),
        ),
        transform: _transform(),
      );

      expect(
        [
          for (var index = 0; index < 4; index++)
            element.dataHitForPointIndex(index)?.markerColor,
        ],
        const [
          Color(0xFF16A34A),
          Color(0xFFFACC15),
          Color(0xFFF97316),
          Color(0xFFDC2626),
        ],
      );
      expect(
        element.dataHitForPointIndex(3)?.formattedColorValue,
        '80 · Critical',
      );
    });

    test(
      'opacity encoding maps its domain and preserves explicit overrides',
      () {
        final element = SeriesElement(
          series: const ScatterChartSeries(
            id: 'confidence-opacity',
            points: [
              ChartDataPoint(x: 1, y: 5, opacityValue: 0),
              ChartDataPoint(x: 3, y: 5, opacityValue: 50),
              ChartDataPoint(
                x: 5,
                y: 5,
                opacityValue: 100,
                pointStyle: PointStyle(
                  scatterMarkerStyle: ScatterMarkerStyle(opacity: 0.42),
                ),
              ),
              ChartDataPoint(x: 7, y: 5),
            ],
            markerStyle: ScatterMarkerStyle(opacity: 0.8),
            opacityEncoding: ScatterOpacityEncoding(
              minimumOpacity: 0.2,
              maximumOpacity: 0.9,
              minimumValue: 0,
              maximumValue: 100,
              label: 'Confidence',
              unit: '%',
            ),
          ),
          transform: _transform(),
        );

        expect(element.dataHitForPointIndex(0)?.markerOpacity, 0.2);
        expect(
          element.dataHitForPointIndex(1)?.markerOpacity,
          closeTo(0.55, 1e-9),
        );
        expect(element.dataHitForPointIndex(2)?.markerOpacity, 0.42);
        expect(element.dataHitForPointIndex(3)?.markerOpacity, 0.8);
        expect(element.dataHitForPointIndex(1)?.formattedOpacityValue, '50 %');
        expect(element.dataHitForPointIndex(1)?.opacityLabel, 'Confidence');
        expect(element.visibleScatterPointIndices, [0, 1, 2, 3]);
      },
    );

    test('bubble rules omit invalid magnitudes and keep zero inspectable', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'bubble-validity',
          points: [
            ChartDataPoint(x: 1, y: 5),
            ChartDataPoint(x: 2, y: 5, magnitude: double.nan),
            ChartDataPoint(x: 3, y: 5, magnitude: -1),
            ChartDataPoint(x: 4, y: 5, magnitude: 0),
          ],
          sizeEncoding: ScatterSizeEncoding(),
        ),
        transform: _transform(),
      );

      expect(element.visibleScatterPointIndices, [3]);
      expect(element.scatterGeometryForPoint(3)?.width, closeTo(34.4, 0.1));
      final hit = element.dataHitForPointIndex(3);
      expect(hit?.radiusValue, 0);
      expect(hit?.formattedRadiusValue, '0');
      expect(hit?.radiusLabel, 'Magnitude');
    });

    test('explicit point radius overrides bubble validity and geometry', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'bubble-override',
          points: [
            ChartDataPoint(
              x: 5,
              y: 5,
              magnitude: -10,
              pointStyle: PointStyle(size: 12),
            ),
          ],
          sizeEncoding: ScatterSizeEncoding(),
        ),
        transform: _transform(),
      );

      expect(element.scatterGeometryForPoint(0)?.width, 24);
      expect(element.hitTest(const Offset(61, 50)), isTrue);
    });

    test('selection feedback adds shape-aware geometry', () async {
      final plainPixels = await _paintedPixelCount(markerRadius: 5);
      final selectedPixels = await _paintedPixelCount(
        markerRadius: 5,
        selectedPointIndices: const {0},
        hasAnySelectedPoints: true,
      );

      expect(selectedPixels, greaterThan(plainPixels));
    });

    test('focus feedback adds an independent shape-aware outline', () async {
      final plainPixels = await _paintedPixelCount(markerRadius: 5);
      final focusedPixels = await _paintedPixelCount(
        markerRadius: 5,
        focusedPointIndices: const {0},
      );

      expect(focusedPixels, greaterThan(plainPixels));
    });

    test(
      'unselected feedback dims marker opacity while selection is active',
      () async {
        final plainAlpha = await _paintedMarkerCenterAlpha();
        final dimmedAlpha = await _paintedMarkerCenterAlpha(
          selectedPointIndices: const {0},
          hasAnySelectedPoints: true,
        );

        expect(plainAlpha, greaterThan(0));
        expect(dimmedAlpha, greaterThan(0));
        expect(dimmedAlpha, lessThan(plainAlpha * 0.4));
      },
    );

    test('hover feedback paints through the uncached overlay path', () async {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'hover-overlay',
          points: [ChartDataPoint(x: 5, y: 5)],
          markerRadius: 6,
          markerShape: SeriesMarkerShape.invertedTriangle,
        ),
        transform: _transform(),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      element.paintScatterInteractionOverlay(canvas, hoveredPointIndex: 0);
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      var paintedPixels = 0;
      for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
        if (bytes.getUint8(offset) > 0) paintedPixels++;
      }
      image.dispose();
      picture.dispose();

      expect(paintedPixels, greaterThan(0));
    });

    test('press feedback paints through the uncached overlay path', () async {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'press-overlay',
          points: [ChartDataPoint(x: 5, y: 5)],
          markerRadius: 6,
          markerShape: SeriesMarkerShape.star,
        ),
        transform: _transform(),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      element.paintScatterInteractionOverlay(canvas, pressedPointIndex: 0);
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      var paintedPixels = 0;
      for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
        if (bytes.getUint8(offset) > 0) paintedPixels++;
      }
      image.dispose();
      picture.dispose();

      expect(paintedPixels, greaterThan(0));
    });
  });
}

Future<int> _paintedPixelCount({
  required double markerRadius,
  Set<int> selectedPointIndices = const {},
  Set<int> focusedPointIndices = const {},
  bool hasAnySelectedPoints = false,
}) async {
  final element = SeriesElement(
    series: ScatterChartSeries(
      id: 'paint-radius-$markerRadius',
      points: const [ChartDataPoint(x: 5, y: 5)],
      markerRadius: markerRadius,
      color: const Color(0xFF2563EB),
    ),
    transform: _transform(),
    seriesTheme: SeriesTheme.highContrast,
    selectedPointIndices: selectedPointIndices,
    focusedPointIndices: focusedPointIndices,
    hasAnySelectedPoints: hasAnySelectedPoints,
  );
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), const Size(100, 100));
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
  var paintedPixels = 0;
  for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
    if (bytes.getUint8(offset) > 0) paintedPixels++;
  }
  image.dispose();
  picture.dispose();
  return paintedPixels;
}

Future<int> _paintedMarkerCenterAlpha({
  Set<int> selectedPointIndices = const {},
  bool hasAnySelectedPoints = false,
}) async {
  final element = SeriesElement(
    series: const ScatterChartSeries(
      id: 'paint-state-alpha',
      points: [ChartDataPoint(x: 3, y: 5), ChartDataPoint(x: 7, y: 5)],
      markerRadius: 6,
      color: Color(0xFF2563EB),
      interactionStyle: ScatterInteractionStyle(dimmedOpacity: 0.2),
    ),
    transform: _transform(),
    selectedPointIndices: selectedPointIndices,
    hasAnySelectedPoints: hasAnySelectedPoints,
  );
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), const Size(100, 100));
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
  const sampleX = 70;
  const sampleY = 50;
  final alpha = bytes!.getUint8((sampleY * 100 + sampleX) * 4 + 3);
  image.dispose();
  picture.dispose();
  return alpha;
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 10,
  plotWidth: 100,
  plotHeight: 100,
);
