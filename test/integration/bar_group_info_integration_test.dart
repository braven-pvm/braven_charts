// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';
import 'dart:ui'
    show Canvas, Color, ImageByteFormat, Offset, PictureRecorder, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/utils/data_converter.dart';

void main() {
  group('BarGroupInfo integration', () {
    test('BarGroupInfo is exported from public API', () {
      // This test verifies that BarGroupInfo can be imported from the main package
      const info = BarGroupInfo(index: 0, count: 3);
      expect(info, isA<BarGroupInfo>());
    });

    test('SeriesElement accepts barGroupInfo parameter', () {
      // Create test data
      const series = BarChartSeries(
        id: 'test',
        points: [ChartDataPoint(x: 1, y: 10), ChartDataPoint(x: 2, y: 20)],
        barWidthPercent: 0.8,
      );

      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
      );

      const barGroupInfo = BarGroupInfo(index: 1, count: 3, gap: 2.0);

      // Create SeriesElement with barGroupInfo
      final element = SeriesElement(
        series: series,
        transform: transform,
        barGroupInfo: barGroupInfo,
      );

      expect(element.barGroupInfo, equals(barGroupInfo));
      expect(element.barGroupInfo?.index, equals(1));
      expect(element.barGroupInfo?.count, equals(3));
      expect(element.barGroupInfo?.gap, equals(2.0));
    });

    test('SeriesElement barGroupInfo is optional (null by default)', () {
      const series = LineChartSeries(
        id: 'test',
        points: [ChartDataPoint(x: 1, y: 10), ChartDataPoint(x: 2, y: 20)],
      );

      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
      );

      // Create SeriesElement without barGroupInfo
      final element = SeriesElement(series: series, transform: transform);

      expect(element.barGroupInfo, isNull);
    });

    test('range-end labels render in a dense grouped slot', () {
      final formattedValues = <double>[];
      final series = BarChartSeries(
        id: 'temperature-range',
        points: const [ChartDataPoint(x: 1, y: 31)],
        rangeStartValues: const [19],
        unit: 'degrees Celsius',
        barWidthPercent: 0.9,
        labelStyle: BarLabelStyle(
          show: true,
          position: BarLabelPosition.rangeEnds,
          valueMode: BarLabelValueMode.range,
          showUnit: true,
          formatter: (point) {
            formattedValues.add(point.y);
            return '${point.y} degrees Celsius';
          },
        ),
      );
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 2,
        dataYMin: 10,
        dataYMax: 40,
        plotWidth: 240,
        plotHeight: 200,
      );
      const groupInfo = BarGroupInfo(index: 1, count: 8, gap: 2);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => SeriesElement(
          series: series,
          transform: transform,
          barGroupInfo: groupInfo,
        ).paint(canvas, const Size(240, 200)),
        returnsNormally,
      );

      expect(formattedValues, [31, 19]);
      recorder.endRecording().dispose();
    });

    test('DataConverter assigns BarGroupInfo for multiple bar series', () {
      // Create two bar series (like in fit_distribution_page)
      const barSeries1 = BarChartSeries(
        id: 'time_distribution',
        name: 'Time in band',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 200),
          ChartDataPoint(x: 2, y: 150),
        ],
        barWidthPercent: 0.7,
      );

      const barSeries2 = BarChartSeries(
        id: 'work_distribution',
        name: 'Work in band',
        points: [
          ChartDataPoint(x: 0, y: 50),
          ChartDataPoint(x: 1, y: 80),
          ChartDataPoint(x: 2, y: 60),
        ],
        barWidthPercent: 0.7,
      );

      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 3,
        dataYMin: 0,
        dataYMax: 200,
        plotWidth: 400,
        plotHeight: 300,
      );

      // Convert using DataConverter (this is what BravenChartPlus does)
      final elements = DataConverter.seriesToElements(
        series: [barSeries1, barSeries2],
        transform: transform,
      );

      // Verify both elements have BarGroupInfo
      expect(elements.length, equals(2));
      expect(elements[0].barGroupInfo, isNotNull);
      expect(elements[1].barGroupInfo, isNotNull);

      // Verify correct index and count
      expect(elements[0].barGroupInfo!.index, equals(0));
      expect(elements[0].barGroupInfo!.count, equals(2));
      expect(elements[1].barGroupInfo!.index, equals(1));
      expect(elements[1].barGroupInfo!.count, equals(2));

      // Verify offsets are different (bars should be side-by-side)
      const testBarWidth = 30.0;
      final offset0 = elements[0].barGroupInfo!.calculateOffset(testBarWidth);
      final offset1 = elements[1].barGroupInfo!.calculateOffset(testBarWidth);

      expect(offset0, isNot(equals(offset1)));
      // With gap=2, effectiveWidth=32, totalWidth=62
      // offset0 = -31 + 15 + 0*32 = -16
      // offset1 = -31 + 15 + 1*32 = 16
      expect(offset0, closeTo(-16.0, 0.1));
      expect(offset1, closeTo(16.0, 0.1));
    });

    test('DataConverter resolves one shared custom gap for the group', () {
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 2,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 200,
        plotHeight: 100,
      );
      final elements = DataConverter.seriesToElements(
        series: const [
          BarChartSeries(
            id: 'first',
            points: [ChartDataPoint(x: 1, y: 40)],
            barWidthPixels: 48,
            barGap: 4,
          ),
          BarChartSeries(
            id: 'second',
            points: [ChartDataPoint(x: 1, y: 60)],
            barWidthPixels: 48,
            barGap: 10,
          ),
        ],
        transform: transform,
      );

      expect(elements[0].barGroupInfo?.gap, 10);
      expect(elements[1].barGroupInfo?.gap, 10);
    });

    test(
      'DataConverter keeps overlaid bars centered with canonical hit geometry',
      () {
        const transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 2,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 200,
          plotHeight: 100,
        );
        final elements = DataConverter.seriesToElements(
          series: const [
            BarChartSeries(
              id: 'reference',
              points: [ChartDataPoint(x: 1, y: 80)],
              barWidthPixels: 40,
              layoutMode: BarLayoutMode.overlaid,
              groupId: 'comparison',
            ),
            BarChartSeries(
              id: 'actual',
              points: [ChartDataPoint(x: 1, y: 55)],
              barWidthPixels: 40,
              layoutMode: BarLayoutMode.overlaid,
              groupId: 'comparison',
              overlayWidthFactor: 0.5,
            ),
          ],
          transform: transform,
        );

        final reference = elements[0].barGeometryForPoint(0)!;
        final actual = elements[1].barGeometryForPoint(0)!;
        expect(reference.rect.center.dx, actual.rect.center.dx);
        expect(reference.rect.width, 40);
        expect(actual.rect.width, 20);
        expect(elements[0].hitTest(const Offset(115, 60)), isTrue);
        expect(elements[1].hitTest(const Offset(115, 60)), isFalse);
      },
    );

    test('DataConverter bounds include stacked totals', () {
      final bounds = DataConverter.computeDataBounds(const [
        BarChartSeries(
          id: 'first',
          points: [ChartDataPoint(x: 0, y: 40)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
        ),
        BarChartSeries(
          id: 'second',
          points: [ChartDataPoint(x: 0, y: 70)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
        ),
      ]);

      expect(bounds.yMax, greaterThan(110));
      expect(bounds.yMin, lessThanOrEqualTo(0));
    });

    test('DataConverter bounds include floating bar starts and ends', () {
      final bounds = DataConverter.computeDataBounds(const [
        BarChartSeries(
          id: 'range',
          points: [ChartDataPoint(x: 0, y: 60), ChartDataPoint(x: 1, y: 75)],
          barWidthPercent: 0.8,
          rangeStartValues: [40, 55],
        ),
      ]);

      expect(bounds.yMin, closeTo(38.25, 0.001));
      expect(bounds.yMax, closeTo(76.75, 0.001));
    });

    test('DataConverter bounds include cumulative waterfall geometry', () {
      final bounds = DataConverter.computeDataBounds(const [
        BarChartSeries(
          id: 'waterfall',
          points: [
            ChartDataPoint(x: 0, y: 80),
            ChartDataPoint(x: 1, y: 35),
            ChartDataPoint(x: 2, y: -20),
            ChartDataPoint(x: 3, y: 0),
          ],
          barWidthPercent: 0.72,
          layoutMode: BarLayoutMode.waterfall,
          waterfallTotalIndices: {3},
        ),
      ]);

      expect(bounds.yMin, lessThan(0));
      expect(bounds.yMax, greaterThan(115));
    });

    test(
      'DataConverter bounds use normalized values instead of raw totals',
      () {
        final bounds = DataConverter.computeDataBounds(const [
          BarChartSeries(
            id: 'first',
            points: [ChartDataPoint(x: 0, y: 400)],
            barWidthPercent: 0.8,
            layoutMode: BarLayoutMode.normalizedStacked,
          ),
          BarChartSeries(
            id: 'second',
            points: [ChartDataPoint(x: 0, y: 600)],
            barWidthPercent: 0.8,
            layoutMode: BarLayoutMode.normalizedStacked,
          ),
        ]);

        expect(bounds.yMax, closeTo(105, 0.001));
        expect(bounds.yMin, closeTo(-5, 0.001));
      },
    );

    test(
      'SeriesElement bounds and hit testing use rendered bar rectangles',
      () {
        const series = BarChartSeries(
          id: 'geometry',
          points: [ChartDataPoint(x: 1, y: 50)],
          barWidthPixels: 20,
        );
        const transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 4,
          dataYMin: -100,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 200,
        );
        final element = SeriesElement(series: series, transform: transform);

        expect(element.bounds.left, lessThanOrEqualTo(90));
        expect(element.bounds.right, greaterThanOrEqualTo(110));
        expect(element.bounds.top, lessThanOrEqualTo(50));
        expect(element.bounds.bottom, greaterThanOrEqualTo(100));
        expect(element.hitTest(const Offset(100, 75)), isTrue);
        expect(element.hitTest(const Offset(130, 75)), isFalse);
      },
    );

    test(
      'SeriesElement bounds and hit testing transpose with horizontal bars',
      () {
        const series = BarChartSeries(
          id: 'horizontal-geometry',
          points: [ChartDataPoint(x: 1, y: 50)],
          barWidthPixels: 20,
          orientation: BarOrientation.horizontal,
        );
        const transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 2,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 200,
          plotHeight: 100,
          transposed: true,
        );
        final element = SeriesElement(series: series, transform: transform);

        expect(element.bounds.left, lessThanOrEqualTo(0));
        expect(element.bounds.right, greaterThanOrEqualTo(100));
        expect(element.bounds.top, lessThanOrEqualTo(40));
        expect(element.bounds.bottom, greaterThanOrEqualTo(60));
        expect(element.hitTest(const Offset(50, 50)), isTrue);
        expect(element.hitTest(const Offset(50, 75)), isFalse);
        expect(
          element.barGeometryForPoint(0)?.valueEndPoint,
          const Offset(100, 50),
        );
      },
    );

    test(
      'DataConverter rejects horizontal bars mixed with other chart types',
      () {
        const horizontal = BarChartSeries(
          id: 'horizontal',
          points: [ChartDataPoint(x: 0, y: 50)],
          barWidthPercent: 0.7,
          orientation: BarOrientation.horizontal,
        );
        const line = LineChartSeries(
          id: 'line',
          points: [ChartDataPoint(x: 0, y: 50)],
        );
        const transform = ChartTransform(
          dataXMin: 0,
          dataXMax: 1,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 200,
          plotHeight: 100,
          transposed: true,
        );

        expect(
          () => DataConverter.seriesToElements(
            series: const [horizontal, line],
            transform: transform,
          ),
          throwsArgumentError,
        );
      },
    );

    test('DataConverter accepts independent axes for horizontal bars', () {
      final revenue = BarChartSeries(
        id: 'revenue',
        points: const [ChartDataPoint(x: 0, y: 96)],
        barWidthPercent: 0.7,
        orientation: BarOrientation.horizontal,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Revenue',
          unit: r'$k',
        ),
      );
      final conversion = BarChartSeries(
        id: 'conversion',
        points: const [ChartDataPoint(x: 0, y: 82)],
        barWidthPercent: 0.7,
        orientation: BarOrientation.horizontal,
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Conversion',
          unit: '%',
        ),
      );
      const transform = ChartTransform(
        dataXMin: -0.5,
        dataXMax: 0.5,
        dataYMin: -0.05,
        dataYMax: 1.05,
        plotWidth: 200,
        plotHeight: 100,
        transposed: true,
      );

      expect(
        DataConverter.seriesToElements(
          series: [revenue, conversion],
          transform: transform,
        ),
        hasLength(2),
      );
    });

    test('SeriesElement hit testing follows a floating range rectangle', () {
      const series = BarChartSeries(
        id: 'floating-geometry',
        points: [ChartDataPoint(x: 1, y: 60)],
        rangeStartValues: [40],
        barWidthPixels: 20,
      );
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 2,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 200,
        plotHeight: 100,
      );
      final element = SeriesElement(series: series, transform: transform);

      expect(element.hitTest(const Offset(100, 50)), isTrue);
      expect(element.hitTest(const Offset(100, 80)), isFalse);
      expect(element.barGeometryForPoint(0)?.startValue, 40);
      expect(element.barGeometryForPoint(0)?.endValue, 60);
    });

    test('SeriesElement exposes stacked geometry to interaction overlays', () {
      const series = BarChartSeries(
        id: 'stacked-geometry',
        points: [ChartDataPoint(x: 1, y: 30)],
        barWidthPixels: 20,
        layoutMode: BarLayoutMode.stacked,
      );
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 2,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 200,
        plotHeight: 100,
      );
      final element = SeriesElement(
        series: series,
        transform: transform,
        barGroupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {0: 20},
          endValues: {0: 50},
          outerPointIndices: {0},
        ),
      );

      final geometry = element.barGeometryForPoint(0);
      expect(geometry?.startValue, 20);
      expect(geometry?.endValue, 50);
      expect(geometry?.valueEndY, 50);
    });

    test('waterfall painter draws semantic bars and connector lines', () async {
      const series = BarChartSeries(
        id: 'waterfall-paint',
        points: [
          ChartDataPoint(x: 0, y: 60),
          ChartDataPoint(x: 1, y: -20),
          ChartDataPoint(x: 2, y: 0),
        ],
        barWidthPixels: 30,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {2},
        waterfallStyle: BarWaterfallStyle(
          increaseColor: Color(0xFF168AAD),
          decreaseColor: Color(0xFFE15B64),
          totalColor: Color(0xFF5149C6),
          connector: BarWaterfallConnectorStyle(
            color: Color(0xFF7A7A7A),
            width: 2,
          ),
        ),
      );
      const transform = ChartTransform(
        dataXMin: -0.5,
        dataXMax: 2.5,
        dataYMin: 0,
        dataYMax: 80,
        plotWidth: 300,
        plotHeight: 200,
      );
      final element = DataConverter.seriesToElements(
        series: const [series],
        transform: transform,
      ).single;
      final geometries = [
        for (var index = 0; index < series.points.length; index++)
          element.barGeometryForPoint(index)!,
      ];
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      element.paint(canvas, const Size(300, 200));
      final image = await recorder.endRecording().toImage(300, 200);
      final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);
      addTearDown(image.dispose);
      expect(pixels, isNotNull);

      final increase = _rgbaAt(pixels!, 300, geometries[0].rect.center);
      final decrease = _rgbaAt(pixels, 300, geometries[1].rect.center);
      final total = _rgbaAt(pixels, 300, geometries[2].rect.center);
      final connector = _rgbaAt(
        pixels,
        300,
        Offset(
          (geometries[0].rect.right + geometries[1].rect.left) / 2,
          geometries[0].valueEndY,
        ),
      );

      expect(increase.$2, greaterThan(increase.$1));
      expect(decrease.$1, greaterThan(decrease.$2));
      expect(total.$3, greaterThan(total.$2));
      expect(connector.$4, greaterThan(0));
    });
  });
}

(int, int, int, int) _rgbaAt(ByteData pixels, int width, Offset position) {
  final x = position.dx.round().clamp(0, width - 1);
  final height = pixels.lengthInBytes ~/ 4 ~/ width;
  final y = position.dy.round().clamp(0, height - 1);
  final offset = (y * width + x) * 4;
  return (
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
    pixels.getUint8(offset + 3),
  );
}
