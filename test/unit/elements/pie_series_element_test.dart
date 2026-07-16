import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieSeriesElement', () {
    test('participates in the shared cached data-series contract', () {
      final series = PieChartSeries.fromMap(
        id: 'pie',
        values: const {'A': 2, 'B': 1},
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size(320, 240),
        theme: ChartTheme.light,
      );

      expect(element, isA<DataSeriesElement>());
      expect(element.pointCount, 2);
      expect(element.geometry.slices, hasLength(2));
      expect(
        element.hitTest(element.geometry.slices.first.tooltipAnchor),
        isTrue,
      );
      expect(element.hitTest(const Offset(-10, -10)), isFalse);
    });

    test('resolves point override, first-slice color, then theme palette', () {
      final series = PieChartSeries(
        id: 'colors',
        color: const Color(0xFF112233),
        points: const [
          ChartDataPoint(x: 0, y: 1, label: 'A'),
          ChartDataPoint(x: 1, y: 1, label: 'B'),
          ChartDataPoint(
            x: 2,
            y: 1,
            label: 'C',
            pointStyle: PointStyle.color(Color(0xFFABCDEF)),
          ),
        ],
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(280),
        theme: ChartTheme.light,
      );

      expect(element.resolvedSliceColors, [
        const Color(0xFF112233),
        ChartTheme.light.seriesTheme.colorAt(1),
        const Color(0xFFABCDEF),
      ]);
    });

    test(
      'paint writes the expected theme colors into opposite slices',
      () async {
        final series = PieChartSeries.fromMap(
          id: 'pixels',
          values: const {'Right': 1, 'Left': 1},
          pieStyle: const PieChartStyle(
            startAngleDegrees: -90,
            radiusFactor: 1,
            sliceGap: 0,
            borderWidth: 0,
          ),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        );
        final element = PieSeriesElement(
          series: series,
          size: const Size.square(200),
          theme: ChartTheme.light,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        element.paint(canvas, const Size.square(200));
        final image = await recorder.endRecording().toImage(200, 200);
        addTearDown(image.dispose);
        final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        expect(bytes, isNotNull);

        Color pixelAt(int x, int y) {
          final offset = (y * 200 + x) * 4;
          return Color.fromARGB(
            bytes!.getUint8(offset + 3),
            bytes.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          );
        }

        expect(pixelAt(145, 100), ChartTheme.light.seriesTheme.colorAt(0));
        expect(pixelAt(55, 100), ChartTheme.light.seriesTheme.colorAt(1));
      },
    );

    test('copyWith preserves geometry inputs and updates element state', () {
      final element = PieSeriesElement(
        series: PieChartSeries.fromMap(id: 'copy', values: const {'A': 1}),
        size: const Size.square(200),
        theme: ChartTheme.dark,
        selectedPointIndices: const {0},
      );

      final copied = element.copyWith(isHovered: true, isSelected: true);
      expect(copied.isHovered, isTrue);
      expect(copied.isSelected, isTrue);
      expect(copied.geometry.slices.single.explodeOffset.distance, 8);
      expect(copied.theme, same(ChartTheme.dark));
    });
  });
}
