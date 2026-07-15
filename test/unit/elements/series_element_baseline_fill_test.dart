import 'dart:ui';
import 'dart:typed_data';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final interpolation in const [
    LineInterpolation.monotone,
    LineInterpolation.bezier,
  ]) {
    test(
      '$interpolation baseline fill follows the rendered curve boundary',
      () async {
        const imageWidth = 800;
        const imageHeight = 720;
        const plotWidth = 800.0;
        const plotHeight = 720.0;
        const baseline = 120.0;
        const dataPoints = <ChartDataPoint>[
          ChartDataPoint(x: 0, y: 105),
          ChartDataPoint(x: 1, y: 138),
          ChartDataPoint(x: 2, y: 155),
          ChartDataPoint(x: 3, y: 148),
          ChartDataPoint(x: 4, y: 112),
        ];
        const transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 4,
          dataYMin: 80,
          dataYMax: 170,
          plotWidth: plotWidth,
          plotHeight: plotHeight,
        );
        final series = AreaChartSeries(
          id: 'power',
          points: dataPoints,
          interpolation: interpolation,
          color: Color(0xFF111111),
          strokeWidth: 1,
          baselineValue: baseline,
          aboveBaselineFillColor: Color(0xFF00BCD4),
          belowBaselineFillColor: Color(0xFFF44336),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        SeriesElement(
          series: series,
          transform: transform,
        ).paint(canvas, const Size(plotWidth, plotHeight));
        final image = await recorder.endRecording().toImage(
          imageWidth,
          imageHeight,
        );
        final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
        addTearDown(image.dispose);
        expect(pixels, isNotNull);

        final plotPoints = dataPoints
            .map((point) => transform.dataToPlot(point.x, point.y))
            .toList();
        final baselineY = transform.dataToPlot(0, baseline).dy;

        for (
          var segmentIndex = 0;
          segmentIndex < plotPoints.length - 1;
          segmentIndex++
        ) {
          final startX = plotPoints[segmentIndex].dx;
          final endX = plotPoints[segmentIndex + 1].dx;

          for (var x = startX + 8; x < endX - 8; x += 8) {
            final curveY = InterpolationGeometry.interpolateYForX<Offset>(
              points: plotPoints,
              startIndex: segmentIndex,
              targetX: x,
              interpolation: interpolation,
              getX: (point) => point.dx,
              getY: (point) => point.dy,
            );
            if ((curveY - baselineY).abs() < 8) continue;

            final directionToBaseline = baselineY > curveY ? 1 : -1;
            final insideY = curveY + directionToBaseline * 4;
            final outsideY = curveY - directionToBaseline * 4;
            final insideAlpha = _alphaAt(pixels!, imageWidth, x, insideY);
            final outsideAlpha = _alphaAt(pixels, imageWidth, x, outsideY);

            expect(
              insideAlpha,
              greaterThan(0),
              reason: 'fill gap at x=$x, curveY=$curveY',
            );
            expect(
              outsideAlpha,
              0,
              reason: 'fill extends beyond curve at x=$x, curveY=$curveY',
            );
          }
        }
      },
    );
  }
}

int _alphaAt(ByteData pixels, int width, double x, double y) {
  final pixelX = x.round().clamp(0, width - 1);
  final pixelY = y.round().clamp(0, (pixels.lengthInBytes ~/ 4 ~/ width) - 1);
  return pixels.getUint8((pixelY * width + pixelX) * 4 + 3);
}
