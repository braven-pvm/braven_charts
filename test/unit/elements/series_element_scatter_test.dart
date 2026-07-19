import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
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

    test('selection and focus feedback add shape-aware geometry', () async {
      final plainPixels = await _paintedPixelCount(markerRadius: 5);
      final linkedPixels = await _paintedPixelCount(
        markerRadius: 5,
        selectedPointIndices: const {0},
        focusedPointIndices: const {0},
        hasAnySelectedPoints: true,
      );

      expect(linkedPixels, greaterThan(plainPixels));
    });

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

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 10,
  plotWidth: 100,
  plotHeight: 100,
);
