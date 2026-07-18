import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter/material.dart' show Alignment;
import 'package:flutter_test/flutter_test.dart';

const _transform = ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 10,
  plotWidth: 100,
  plotHeight: 100,
);

void main() {
  const points = [ChartDataPoint(x: 0, y: 8), ChartDataPoint(x: 10, y: 8)];

  test('Area gradient paints a vertical color blend inside the fill', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: points,
      color: ui.Color(0xFF111827),
      fillOpacity: 1,
      fillGradient: AreaGradient(
        colors: [ui.Color(0xFFFF0000), ui.Color(0xFF0000FF)],
      ),
    );

    final bytes = await _paint(series);
    final upper = _pixelAt(bytes, 50, 30);
    final lower = _pixelAt(bytes, 50, 85);

    expect(upper.red, greaterThan(upper.blue));
    expect(lower.blue, greaterThan(lower.red));
    expect(upper.alpha, 255);
    expect(lower.alpha, 255);
  });

  test('Area fill remains solid when no gradient is configured', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: points,
      color: ui.Color(0xFF7C3AED),
      fillOpacity: 1,
    );

    final bytes = await _paint(series);
    final upper = _pixelAt(bytes, 50, 30);
    final lower = _pixelAt(bytes, 50, 85);

    expect(upper, lower);
    expect(upper.red, 124);
    expect(upper.green, 58);
    expect(upper.blue, 237);
  });

  test('Area gradient composes stop alpha with fill opacity', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: points,
      fillOpacity: 0.5,
      fillGradient: AreaGradient(
        colors: [ui.Color(0xFFFF0000), ui.Color(0x00FF0000)],
        stops: [0, 1],
      ),
    );

    final bytes = await _paint(series);
    final upper = _pixelAt(bytes, 50, 30);
    final lower = _pixelAt(bytes, 50, 85);

    expect(upper.alpha, inInclusiveRange(80, 120));
    expect(lower.alpha, lessThan(upper.alpha));
  });

  test('Area gradient honors directional begin and end alignment', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: points,
      fillOpacity: 1,
      fillGradient: AreaGradient(
        colors: [ui.Color(0xFF00FF00), ui.Color(0xFFFF00FF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );

    final bytes = await _paint(series);
    final left = _pixelAt(bytes, 15, 70);
    final right = _pixelAt(bytes, 85, 70);

    expect(left.green, greaterThan(left.red));
    expect(right.red, greaterThan(right.green));
  });

  test('baseline fills take precedence over the Area gradient', () async {
    const series = AreaChartSeries(
      id: 'area',
      points: points,
      fillOpacity: 1,
      fillGradient: AreaGradient(
        colors: [ui.Color(0xFF00FF00), ui.Color(0xFF00FF00)],
      ),
      baselineValue: 5,
      aboveBaselineFillColor: ui.Color(0xFFFF0000),
      belowBaselineFillColor: ui.Color(0xFF0000FF),
    );

    final bytes = await _paint(series);
    final fill = _pixelAt(bytes, 50, 35);

    expect(fill.red, greaterThan(240));
    expect(fill.green, lessThan(15));
    expect(fill.blue, lessThan(15));
  });
}

Future<ByteData> _paint(AreaChartSeries series) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  SeriesElement(
    series: series,
    transform: _transform,
  ).paint(canvas, const ui.Size(100, 100));
  final image = await recorder.endRecording().toImage(100, 100);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!;
}

({int red, int green, int blue, int alpha}) _pixelAt(
  ByteData bytes,
  int x,
  int y,
) {
  final offset = ((y * 100) + x) * 4;
  return (
    red: bytes.getUint8(offset),
    green: bytes.getUint8(offset + 1),
    blue: bytes.getUint8(offset + 2),
    alpha: bytes.getUint8(offset + 3),
  );
}
