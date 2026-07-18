import 'dart:ui' as ui;
import 'dart:typed_data';

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

  test('reveal clips Line paint and interaction to the same edge', () async {
    const series = LineChartSeries(
      id: 'line',
      points: [ChartDataPoint(x: 0, y: 5), ChartDataPoint(x: 10, y: 5)],
      color: ui.Color(0xFFFF0000),
      strokeWidth: 4,
      showDataPointMarkers: true,
    );
    final element = SeriesElement(
      series: series,
      transform: transform,
      revealProgress: 0.5,
    );

    expect(element.bounds.right, 50);
    expect(element.hitTest(const ui.Offset(25, 50)), isTrue);
    expect(element.hitTest(const ui.Offset(75, 50)), isFalse);
    expect(element.dataHitForPointIndex(0), isNotNull);
    expect(element.dataHitForPointIndex(1), isNull);

    final bytes = await _paint(element);
    expect(_alphaAt(bytes, 25, 50), greaterThan(0));
    expect(_alphaAt(bytes, 75, 50), 0);
  });

  test('Area fill and stroke share the reveal boundary', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: [ChartDataPoint(x: 0, y: 5), ChartDataPoint(x: 10, y: 5)],
      color: ui.Color(0xFF2563EB),
      fillOpacity: 0.5,
    );
    final element = SeriesElement(
      series: series,
      transform: transform,
      revealProgress: 0.5,
    );

    final bytes = await _paint(element);
    expect(_alphaAt(bytes, 25, 75), greaterThan(0));
    expect(_alphaAt(bytes, 75, 75), 0);
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

int _alphaAt(ByteData bytes, int x, int y) =>
    bytes.getUint8(((y * 100) + x) * 4 + 3);
