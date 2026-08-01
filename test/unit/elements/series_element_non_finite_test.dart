import 'dart:typed_data';
import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/data_point_label_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transform = ChartTransform(
    dataXMin: 0,
    dataXMax: 4,
    dataYMin: 0,
    dataYMax: 50,
    plotWidth: 400,
    plotHeight: 300,
  );

  for (final nonFiniteY in <double>[
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test(
      'line paint treats $nonFiniteY as a gap with markers and labels',
      () async {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final element = SeriesElement(
          series: LineChartSeries(
            id: 'weekly-training-time',
            points: [
              const ChartDataPoint(x: 0, y: 10, label: 'Week 1'),
              const ChartDataPoint(x: 1, y: 20, label: 'Week 2'),
              ChartDataPoint(x: 2, y: nonFiniteY, label: 'Omitted zone'),
              const ChartDataPoint(x: 3, y: 30, label: 'Week 4'),
              const ChartDataPoint(x: 4, y: 40, label: 'Week 5'),
            ],
            interpolation: LineInterpolation.monotone,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 4,
            dataPointLabels: const DataPointLabelConfig(show: true),
          ),
          transform: transform,
        );

        element.paint(canvas, const Size(400, 300));
        final image = await recorder.endRecording().toImage(400, 300);
        addTearDown(image.dispose);
        final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);

        expect(pixels, isNotNull);
        expect(
          _alphaAt(pixels!, 400, 200, 150),
          0,
          reason: 'a non-finite observation must break, not bridge, the line',
        );
        expect(
          _alphaAt(pixels, 400, 50, 210),
          greaterThan(0),
          reason: 'finite observations before the gap must remain visible',
        );
        expect(
          _alphaAt(pixels, 400, 350, 90),
          greaterThan(0),
          reason: 'finite observations after the gap must remain visible',
        );
      },
    );
  }

  test('line hit geometry does not bridge a non-finite gap', () {
    final element = SeriesElement(
      series: const LineChartSeries(
        id: 'weekly-training-time',
        points: [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: double.nan),
          ChartDataPoint(x: 3, y: 30),
          ChartDataPoint(x: 4, y: 40),
        ],
        interpolation: LineInterpolation.monotone,
      ),
      transform: transform,
    );

    expect(element.pathHitDistance(const Offset(50, 210)), lessThan(0.01));
    expect(
      element.pathHitDistance(const Offset(200, 150)),
      greaterThan(100),
      reason: 'the missing observation must not create interactive geometry',
    );
  });

  test(
    'a non-finite X keeps finite observations on both sides visible',
    () async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final element = SeriesElement(
        series: const LineChartSeries(
          id: 'invalid-date',
          points: [
            ChartDataPoint(x: 0, y: 10),
            ChartDataPoint(x: 1, y: 20),
            ChartDataPoint(x: double.nan, y: 25),
            ChartDataPoint(x: 3, y: 30),
            ChartDataPoint(x: 4, y: 40),
          ],
          interpolation: LineInterpolation.monotone,
          showDataPointMarkers: true,
        ),
        transform: transform,
      );

      element.paint(canvas, const Size(400, 300));
      final image = await recorder.endRecording().toImage(400, 300);
      addTearDown(image.dispose);
      final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);

      expect(pixels, isNotNull);
      expect(_alphaAt(pixels!, 400, 50, 210), greaterThan(0));
      expect(_alphaAt(pixels, 400, 350, 90), greaterThan(0));
      expect(_alphaAt(pixels, 400, 200, 150), 0);
    },
  );
}

int _alphaAt(ByteData pixels, int width, double x, double y) {
  final pixelX = x.round().clamp(0, width - 1);
  final height = pixels.lengthInBytes ~/ 4 ~/ width;
  final pixelY = y.round().clamp(0, height - 1);
  return pixels.getUint8((pixelY * width + pixelX) * 4 + 3);
}
