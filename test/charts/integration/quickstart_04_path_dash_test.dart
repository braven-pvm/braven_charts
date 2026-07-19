import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
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

  test('Line series paints intervals after every interpolation mode', () async {
    for (final interpolation in LineInterpolation.values) {
      final series = LineChartSeries(
        id: 'forecast-${interpolation.name}',
        points: points,
        color: const ui.Color(0xFF2563EB),
        interpolation: interpolation,
        strokeWidth: 2,
        dashPattern: const [10, 10],
      );

      final bytes = await _paint(series);

      expect(
        _alphaAt(bytes, 5, 20),
        greaterThan(0),
        reason: interpolation.name,
      );
      expect(_alphaAt(bytes, 15, 20), 0, reason: interpolation.name);
      expect(
        _alphaAt(bytes, 25, 20),
        greaterThan(0),
        reason: interpolation.name,
      );
    }
  });

  test(
    'Area series keeps its fill continuous while patterning the edge',
    () async {
      const series = AreaChartSeries(
        id: 'range',
        points: points,
        color: ui.Color(0xFF7C3AED),
        strokeWidth: 2,
        fillOpacity: 1,
        dashPattern: [10, 10],
      );

      final bytes = await _paint(series);

      expect(_alphaAt(bytes, 5, 19), greaterThan(0));
      expect(_alphaAt(bytes, 15, 19), 0);
      expect(_alphaAt(bytes, 5, 50), greaterThan(0));
      expect(_alphaAt(bytes, 15, 50), greaterThan(0));
    },
  );

  test('patterned outlines compose with segment styles and glow', () async {
    const series = LineChartSeries(
      id: 'styled-forecast',
      points: [
        ChartDataPoint(x: 0, y: 8),
        ChartDataPoint(
          x: 5,
          y: 8,
          segmentStyle: SegmentStyle(color: ui.Color(0xFFEF4444)),
        ),
        ChartDataPoint(x: 10, y: 8),
      ],
      color: ui.Color(0xFF2563EB),
      strokeWidth: 2,
      lineGlow: 3,
      dashPattern: [10, 10],
    );

    final bytes = await _paint(series);

    expect(_alphaAt(bytes, 5, 20), greaterThan(0));
    expect(_alphaAt(bytes, 5, 16), greaterThan(0));
  });

  test(
    'a segment pattern changes paint without splitting interpolation',
    () async {
      const series = LineChartSeries(
        id: 'continuous-forecast',
        points: [
          ChartDataPoint(x: 0, y: 8),
          ChartDataPoint(
            x: 5,
            y: 8,
            segmentStyle: SegmentStyle(dashPattern: [10, 10]),
          ),
          ChartDataPoint(x: 10, y: 8),
        ],
        color: ui.Color(0xFF2563EB),
        strokeWidth: 2,
      );

      final bytes = await _paint(series);

      expect(_alphaAt(bytes, 45, 20), greaterThan(0));
      expect(_alphaAt(bytes, 55, 20), greaterThan(0));
      expect(_alphaAt(bytes, 65, 20), 0);
      expect(_alphaAt(bytes, 75, 20), greaterThan(0));
    },
  );

  test(
    'an empty segment pattern restores solid over a dashed series',
    () async {
      const series = LineChartSeries(
        id: 'solid-override',
        points: [
          ChartDataPoint(x: 0, y: 8),
          ChartDataPoint(
            x: 5,
            y: 8,
            segmentStyle: SegmentStyle(dashPattern: []),
          ),
          ChartDataPoint(x: 10, y: 8),
        ],
        color: ui.Color(0xFF2563EB),
        strokeWidth: 2,
        dashPattern: [10, 10],
      );

      final bytes = await _paint(series);

      expect(_alphaAt(bytes, 15, 20), 0);
      expect(_alphaAt(bytes, 65, 20), greaterThan(0));
    },
  );

  test(
    'baseline Area keeps clipped fills continuous across a segment pattern',
    () async {
      const series = AreaChartSeries(
        id: 'baseline-range',
        points: [
          ChartDataPoint(x: 0, y: 8),
          ChartDataPoint(
            x: 5,
            y: 8,
            segmentStyle: SegmentStyle(dashPattern: [10, 10]),
          ),
          ChartDataPoint(x: 10, y: 8),
        ],
        color: ui.Color(0xFF7C3AED),
        strokeWidth: 2,
        fillOpacity: 1,
        baselineValue: 5,
        aboveBaselineFillColor: ui.Color(0xFF10B981),
        belowBaselineFillColor: ui.Color(0xFFEF4444),
      );

      final bytes = await _paint(series);

      expect(_alphaAt(bytes, 15, 19), greaterThan(0));
      expect(_alphaAt(bytes, 55, 19), greaterThan(0));
      expect(_alphaAt(bytes, 65, 19), 0);
      expect(_alphaAt(bytes, 65, 35), greaterThan(0));
    },
  );
}

Future<ByteData> _paint(ChartSeries series) async {
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

int _alphaAt(ByteData bytes, int x, int y) =>
    bytes.getUint8((((y * 100) + x) * 4) + 3);
