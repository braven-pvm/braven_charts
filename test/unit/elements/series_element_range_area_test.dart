import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transform = ChartTransform(
    dataXMin: 0,
    dataXMax: 10,
    dataYMin: 0,
    dataYMax: 10,
    plotWidth: 100,
    plotHeight: 100,
  );

  test(
    'Range Area paints between low and high without filling outside',
    () async {
      final element = SeriesElement(
        series: RangeAreaChartSeries(
          id: 'range',
          points: [
            RangeAreaDataPoint(x: 0, low: 2, high: 8),
            RangeAreaDataPoint(x: 10, low: 2, high: 8),
          ],
          color: const ui.Color(0xFF2563EB),
          fillOpacity: 1,
          borderMode: RangeAreaBorderMode.none,
        ),
        transform: transform,
      );

      final bytes = await _paint(element);
      expect(_alphaAt(bytes, 50, 50), greaterThan(0));
      expect(_alphaAt(bytes, 50, 10), 0);
      expect(_alphaAt(bytes, 50, 90), 0);
    },
  );

  test('band hit policy resolves interval interior and original identity', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 3, high: 7),
        ],
        hitTestMode: RangeAreaHitTestMode.band,
      ),
      transform: transform,
    );

    expect(element.hitTest(const ui.Offset(50, 50)), isTrue);
    expect(element.hitTest(const ui.Offset(50, 5)), isFalse);
    final hit = element.dataHitAt(const ui.Offset(92, 50));
    expect(hit, isNotNull);
    expect(hit!.pointIndex, 1);
    expect(hit.formattedValue, '3.00–7.00');
    expect(hit.rangeArea!.low, 3);
    expect(hit.rangeArea!.high, 7);
    expect(hit.rangeArea!.span, 4);
    expect(hit.semanticLabel, contains('Low 3.00'));
    expect(hit.semanticLabel, contains('High 7.00'));
    expect(hit.semanticLabel, contains('Span 4.00'));
  });

  test('nearest-boundary hit policy excludes the band interior', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
        hitTestMode: RangeAreaHitTestMode.nearestBoundary,
      ),
      transform: transform,
    );

    expect(element.hitTest(const ui.Offset(50, 50)), isFalse);
    expect(element.hitTest(const ui.Offset(50, 21)), isTrue);
    expect(element.hitTest(const ui.Offset(50, 79)), isTrue);
  });

  test('box selection intersects the visible low-to-high interval', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 5, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
      ),
      transform: transform,
    );

    final hits = element.dataHitsInPlotRect(
      const ui.Rect.fromLTRB(46, 18, 54, 26),
    );

    expect(hits, hasLength(1));
    expect(hits.single.pointIndex, 1);
    expect(hits.single.plotPosition, const ui.Offset(50, 50));
    final selectionBounds = hits.single.selectionBounds!;
    expect(selectionBounds.left, closeTo(50, 0.001));
    expect(selectionBounds.top, closeTo(20, 0.001));
    expect(selectionBounds.right, closeTo(50, 0.001));
    expect(selectionBounds.bottom, closeTo(80, 0.001));
  });

  test('lasso selection intersects a visible Range Area boundary', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 5, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
      ),
      transform: transform,
    );

    final hits = element.dataHitsInPlotPolygon(const [
      ui.Offset(46, 16),
      ui.Offset(54, 16),
      ui.Offset(54, 26),
      ui.Offset(46, 26),
    ]);

    expect(hits, hasLength(1));
    expect(hits.single.pointIndex, 1);
    expect(hits.single.selectionBounds, isNotNull);
  });

  test('selected interval feedback spans both boundaries', () async {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 5, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
        fillOpacity: 0,
        borderMode: RangeAreaBorderMode.none,
      ),
      transform: transform,
      selectedPointIndices: const {1},
    );

    final bytes = await _paint(element);
    expect(_alphaAt(bytes, 50, 50), greaterThan(0));
    expect(_alphaAt(bytes, 50, 20), greaterThan(0));
    expect(_alphaAt(bytes, 50, 80), greaterThan(0));
  });

  test('hovered interval feedback spans both boundaries', () async {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 5, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
        fillOpacity: 0,
        borderMode: RangeAreaBorderMode.none,
        showBoundaryMarkers: false,
      ),
      transform: transform,
    );

    final bytes = await _paintRangeAreaHover(element, pointIndex: 1);
    expect(_alphaAt(bytes, 50, 50), greaterThan(0));
    expect(_alphaAt(bytes, 50, 20), greaterThan(0));
    expect(_alphaAt(bytes, 50, 80), greaterThan(0));
    expect(_alphaAt(bytes, 25, 50), 0);
  });

  test('selected complete band increases its visual emphasis', () async {
    final series = RangeAreaChartSeries(
      id: 'range',
      points: [
        RangeAreaDataPoint(x: 0, low: 2, high: 8),
        RangeAreaDataPoint(x: 10, low: 2, high: 8),
      ],
      color: const ui.Color(0xFF2563EB),
      fillOpacity: 0.2,
      borderMode: RangeAreaBorderMode.none,
    );
    final normal = await _paint(
      SeriesElement(series: series, transform: transform),
    );
    final selected = await _paint(
      SeriesElement(series: series, transform: transform, isSelected: true),
    );

    expect(_alphaAt(selected, 50, 50), greaterThan(_alphaAt(normal, 50, 50)));
  });

  test('hovered complete band increases its visual emphasis', () async {
    final series = RangeAreaChartSeries(
      id: 'range',
      points: [
        RangeAreaDataPoint(x: 0, low: 2, high: 8),
        RangeAreaDataPoint(x: 10, low: 2, high: 8),
      ],
      color: const ui.Color(0xFF2563EB),
      fillOpacity: 0.2,
      borderMode: RangeAreaBorderMode.none,
    );
    final normal = await _paint(
      SeriesElement(series: series, transform: transform),
    );
    final hovered = await _paint(
      SeriesElement(series: series, transform: transform, isHovered: true),
    );

    expect(_alphaAt(hovered, 50, 50), greaterThan(_alphaAt(normal, 50, 50)));
  });

  test('gaps remain non-interactive and preserve visible source indices', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 4, low: 2, high: 8),
          RangeAreaDataPoint.gap(x: 5),
          RangeAreaDataPoint(x: 6, low: 2, high: 8),
          RangeAreaDataPoint(x: 10, low: 2, high: 8),
        ],
      ),
      transform: transform,
    );

    expect(element.visibleRangeAreaRunCount, 2);
    expect(element.visibleRangeAreaPointIndices, [0, 1, 3, 4]);
    expect(element.hitTest(const ui.Offset(50, 50)), isFalse);
  });

  test('RangeAreaTheme participates in ChartTheme copy and equality', () {
    final custom = RangeAreaTheme.light.copyWith(
      fillOpacity: 0.4,
      boundaryWidth: 3,
    );
    final first = ChartTheme.light.copyWith(rangeAreaTheme: custom);
    final second = ChartTheme.light.copyWith(rangeAreaTheme: custom);

    expect(first.rangeAreaTheme.fillOpacity, 0.4);
    expect(first.rangeAreaTheme.boundaryWidth, 3);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}

Future<ByteData> _paint(SeriesElement element) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  element.paint(canvas, const ui.Size(100, 100));
  final image = await recorder.endRecording().toImage(100, 100);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!;
}

Future<ByteData> _paintRangeAreaHover(
  SeriesElement element, {
  required int pointIndex,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  element.paintRangeAreaInteractionOverlay(
    canvas,
    hoveredPointIndex: pointIndex,
  );
  final image = await recorder.endRecording().toImage(100, 100);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!;
}

int _alphaAt(ByteData bytes, int x, int y) =>
    bytes.getUint8(((y * 100) + x) * 4 + 3);
