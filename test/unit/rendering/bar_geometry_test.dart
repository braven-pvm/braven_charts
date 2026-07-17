import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/rendering/bar_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transform = ChartTransform(
    dataXMin: 0,
    dataXMax: 4,
    dataYMin: -100,
    dataYMax: 100,
    plotWidth: 400,
    plotHeight: 200,
  );

  group('BarGeometryEngine', () {
    test('treats barWidthPixels as logical pixels', () {
      const series = BarChartSeries(
        id: 'fixed',
        points: [ChartDataPoint(x: 1, y: 50)],
        barWidthPixels: 24,
      );

      final geometry = BarGeometryEngine.layout(
        series: series,
        transform: transform,
      ).single;

      expect(geometry.rect.width, 24);
      expect(geometry.rect.bottom, 100);
      expect(geometry.rect.top, 50);
    });

    test('uses one rectangle for grouped positioning and hit geometry', () {
      const series = BarChartSeries(
        id: 'grouped',
        points: [ChartDataPoint(x: 2, y: 40)],
        barWidthPixels: 64,
      );

      final first = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(index: 0, count: 2, gap: 4),
      ).single;
      final second = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(index: 1, count: 2, gap: 4),
      ).single;

      expect(first.rect.width, 30);
      expect(second.rect.width, 30);
      expect(first.rect.right + 4, second.rect.left);
      expect((first.rect.center.dx + second.rect.center.dx) / 2, 200);
    });

    test(
      'rounds only the exposed value end for positive and negative bars',
      () {
        const series = BarChartSeries(
          id: 'signed',
          points: [ChartDataPoint(x: 1, y: 50), ChartDataPoint(x: 2, y: -50)],
          barWidthPixels: 20,
          barStyle: BarChartStyle(cornerRadius: 8),
        );

        final geometry = BarGeometryEngine.layout(
          series: series,
          transform: transform,
        );

        expect(geometry[0].rrect.tlRadiusX, 8);
        expect(geometry[0].rrect.blRadiusX, 0);
        expect(geometry[1].rrect.tlRadiusX, 0);
        expect(geometry[1].rrect.blRadiusX, 8);
      },
    );

    test('lays out an explicit track and minimum visible bar length', () {
      const series = BarChartSeries(
        id: 'track',
        points: [ChartDataPoint(x: 1, y: 0.5)],
        barWidthPixels: 20,
        minBarLength: 8,
        trackStyle: BarTrackStyle(color: Color(0xFFE0E0E0), value: 80),
      );

      final geometry = BarGeometryEngine.layout(
        series: series,
        transform: transform,
      ).single;

      expect(geometry.rect.height, 8);
      expect(geometry.trackRect, isNotNull);
      expect(geometry.trackRect!.height, 80);
      expect(geometry.paintBounds.contains(geometry.rect.topCenter), isTrue);
    });

    test('provides an accessible hit width for thin rods', () {
      const series = BarChartSeries(
        id: 'rod',
        points: [ChartDataPoint(x: 1, y: 50)],
        barWidthPixels: 4,
      );

      final geometry = BarGeometryEngine.layout(
        series: series,
        transform: transform,
      ).single;

      expect(geometry.rect.width, 4);
      expect(geometry.hitBounds.width, 8);
    });

    test(
      'transposes category spacing and value geometry for horizontal bars',
      () {
        const horizontalTransform = ChartTransform(
          dataXMin: 0,
          dataXMax: 4,
          dataYMin: -100,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 200,
          transposed: true,
        );
        const series = BarChartSeries(
          id: 'horizontal',
          points: [ChartDataPoint(x: 1, y: 50), ChartDataPoint(x: 2, y: -50)],
          barWidthPixels: 20,
          orientation: BarOrientation.horizontal,
          barStyle: BarChartStyle(cornerRadius: 8),
        );

        final geometry = BarGeometryEngine.layout(
          series: series,
          transform: horizontalTransform,
        );

        expect(geometry[0].rect, const Rect.fromLTRB(200, 40, 300, 60));
        expect(geometry[0].valueEndPoint, const Offset(300, 50));
        expect(geometry[0].rrect.trRadiusX, 8);
        expect(geometry[0].rrect.tlRadiusX, 0);
        expect(geometry[1].rect, const Rect.fromLTRB(100, 90, 200, 110));
        expect(geometry[1].valueEndPoint, const Offset(100, 100));
        expect(geometry[1].rrect.tlRadiusX, 8);
        expect(geometry[1].rrect.trRadiusX, 0);
      },
    );

    test(
      'expands thin horizontal bars along the category axis for hit testing',
      () {
        const horizontalTransform = ChartTransform(
          dataXMin: 0,
          dataXMax: 2,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 200,
          plotHeight: 100,
          transposed: true,
        );
        const series = BarChartSeries(
          id: 'horizontal-rod',
          points: [ChartDataPoint(x: 1, y: 50)],
          barWidthPixels: 4,
          orientation: BarOrientation.horizontal,
        );

        final geometry = BarGeometryEngine.layout(
          series: series,
          transform: horizontalTransform,
        ).single;

        expect(geometry.rect.height, 4);
        expect(geometry.hitBounds.height, 8);
        expect(geometry.hitBounds.width, geometry.rect.width);
      },
    );

    test('overlaid bars share a center and retain independent widths', () {
      const reference = BarChartSeries(
        id: 'reference',
        points: [ChartDataPoint(x: 1, y: 70)],
        barWidthPixels: 40,
        layoutMode: BarLayoutMode.overlaid,
      );
      const actual = BarChartSeries(
        id: 'actual',
        points: [ChartDataPoint(x: 1, y: 55)],
        barWidthPixels: 40,
        layoutMode: BarLayoutMode.overlaid,
        overlayWidthFactor: 0.5,
      );
      const groupInfo = BarGroupInfo(
        index: 0,
        count: 1,
        layoutMode: BarLayoutMode.overlaid,
      );

      final referenceGeometry = BarGeometryEngine.layout(
        series: reference,
        transform: transform,
        groupInfo: groupInfo,
      ).single;
      final actualGeometry = BarGeometryEngine.layout(
        series: actual,
        transform: transform,
        groupInfo: groupInfo,
      ).single;

      expect(actualGeometry.rect.center.dx, referenceGeometry.rect.center.dx);
      expect(referenceGeometry.rect.width, 40);
      expect(actualGeometry.rect.width, 20);
      expect(actualGeometry.startValue, 0);
      expect(actualGeometry.endValue, 55);
    });

    test('overlaid bars can shift within their shared category slot', () {
      const reference = BarChartSeries(
        id: 'reference',
        points: [ChartDataPoint(x: 1, y: 38)],
        barWidthPixels: 40,
        layoutMode: BarLayoutMode.overlaid,
        overlayOffsetFactor: -0.15,
      );
      const actual = BarChartSeries(
        id: 'actual',
        points: [ChartDataPoint(x: 1, y: 40)],
        barWidthPixels: 40,
        layoutMode: BarLayoutMode.overlaid,
        overlayOffsetFactor: 0.15,
      );
      const groupInfo = BarGroupInfo(
        index: 0,
        count: 1,
        layoutMode: BarLayoutMode.overlaid,
      );

      final referenceGeometry = BarGeometryEngine.layout(
        series: reference,
        transform: transform,
        groupInfo: groupInfo,
      ).single;
      final actualGeometry = BarGeometryEngine.layout(
        series: actual,
        transform: transform,
        groupInfo: groupInfo,
      ).single;

      expect(referenceGeometry.rect.center.dx, 94);
      expect(actualGeometry.rect.center.dx, 106);
      expect(referenceGeometry.rect.overlaps(actualGeometry.rect), isTrue);
    });

    test(
      'floating bars resolve explicit range starts through canonical geometry',
      () {
        const series = BarChartSeries(
          id: 'range',
          points: [ChartDataPoint(x: 1, y: 60), ChartDataPoint(x: 2, y: 20)],
          barWidthPixels: 20,
          rangeStartValues: [20, 60],
          barStyle: BarChartStyle(
            cornerRadius: 8,
            cornerRadiusPolicy: BarCornerRadiusPolicy.all,
          ),
        );

        final geometry = BarGeometryEngine.layout(
          series: series,
          transform: transform,
        );

        expect(geometry[0].startValue, 20);
        expect(geometry[0].endValue, 60);
        expect(geometry[0].rect.top, closeTo(40, 0.001));
        expect(geometry[0].rect.bottom, closeTo(80, 0.001));
        expect(geometry[0].isNegative, isFalse);
        expect(geometry[1].startValue, 60);
        expect(geometry[1].endValue, 20);
        expect(geometry[1].rect.top, closeTo(40, 0.001));
        expect(geometry[1].rect.bottom, closeTo(80, 0.001));
        expect(geometry[1].isNegative, isTrue);
        expect(geometry[1].rrect.blRadiusX, 8);
      },
    );

    test(
      'range values validate their point alignment and composition mode',
      () {
        const mismatch = BarChartSeries(
          id: 'mismatch',
          points: [ChartDataPoint(x: 1, y: 60)],
          barWidthPixels: 20,
          rangeStartValues: [20, 30],
        );
        expect(
          () =>
              BarGeometryEngine.layout(series: mismatch, transform: transform),
          throwsArgumentError,
        );
        const stackedRange = BarChartSeries(
          id: 'stacked-range',
          points: [ChartDataPoint(x: 1, y: 60)],
          barWidthPixels: 20,
          layoutMode: BarLayoutMode.stacked,
          rangeStartValues: [20],
        );
        expect(
          () => BarGeometryEngine.layout(
            series: stackedRange,
            transform: transform,
          ),
          throwsArgumentError,
        );
      },
    );

    test('value-end rounding only affects the outer stacked segment', () {
      const series = BarChartSeries(
        id: 'stacked',
        points: [ChartDataPoint(x: 1, y: 30)],
        barWidthPixels: 20,
        layoutMode: BarLayoutMode.stacked,
        barStyle: BarChartStyle(
          cornerRadius: 8,
          cornerRadiusPolicy: BarCornerRadiusPolicy.valueEnd,
        ),
      );

      final inner = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {0: 20},
          endValues: {0: 50},
        ),
      ).single;
      final outer = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {0: 20},
          endValues: {0: 50},
          outerPointIndices: {0},
        ),
      ).single;

      expect(inner.startValue, 20);
      expect(inner.endValue, 50);
      expect(inner.rrect.tlRadiusX, 0);
      expect(inner.rrect.blRadiusX, 0);
      expect(outer.rrect.tlRadiusX, 8);
      expect(outer.rrect.blRadiusX, 0);
    });

    test('all-corners rounding applies to every stacked segment', () {
      const series = BarChartSeries(
        id: 'stacked',
        points: [ChartDataPoint(x: 1, y: 30)],
        barWidthPixels: 20,
        layoutMode: BarLayoutMode.stacked,
        barStyle: BarChartStyle(
          cornerRadius: 8,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
        ),
      );

      final inner = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {0: 20},
          endValues: {0: 50},
        ),
      ).single;
      final outer = BarGeometryEngine.layout(
        series: series,
        transform: transform,
        groupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {0: 20},
          endValues: {0: 50},
          outerPointIndices: {0},
        ),
      ).single;

      for (final geometry in [inner, outer]) {
        expect(geometry.rrect.tlRadiusX, 8);
        expect(geometry.rrect.trRadiusX, 8);
        expect(geometry.rrect.blRadiusX, 8);
        expect(geometry.rrect.brRadiusX, 8);
      }
    });
  });
}
