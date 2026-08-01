import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/data_hit.dart';
import 'package:braven_charts/src/interaction/selection/chart_selection_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sharedPoints = <ChartDataPoint>[
    ChartDataPoint(x: 0, y: 10),
    ChartDataPoint(x: 1, y: 20),
    ChartDataPoint(x: 2, y: 30),
  ];

  ChartDataHit hit({
    String seriesId = 'first',
    int pointIndex = 1,
    List<int> sourcePointIndices = const <int>[],
  }) => ChartDataHit(
    seriesId: seriesId,
    pointIndex: pointIndex,
    sourcePointIndices: sourcePointIndices,
    plotPosition: Offset.zero,
    semanticBounds: Rect.zero,
    point: sharedPoints[pointIndex],
    formattedValue: '20',
    ordinal: pointIndex + 1,
    count: sharedPoints.length,
  );

  BarChartSeries bar({
    required String id,
    BarLayoutMode mode = BarLayoutMode.grouped,
    BarOrientation orientation = BarOrientation.vertical,
    String? groupId,
    String? yAxisId,
  }) => BarChartSeries(
    id: id,
    points: sharedPoints,
    barWidthPercent: 0.7,
    layoutMode: mode,
    orientation: orientation,
    groupId: groupId,
    yAxisId: yAxisId,
  );

  group('ChartSelectionResolver', () {
    test('Heatmap row and column expansion stay within the source series', () {
      final cells = <HeatmapDataPoint>[
        HeatmapDataPoint(x: 0, y: 0, value: 10),
        HeatmapDataPoint(x: 1, y: 0, value: 20),
        HeatmapDataPoint(x: 0, y: 1, value: 30),
        HeatmapDataPoint(x: 1, y: 1, value: 40),
      ];
      final matrix = HeatmapChartSeries(
        id: 'matrix',
        points: cells,
        colorScale: HeatmapColorScale.sequential(
          colors: const [Color(0xFFFFFFFF), Color(0xFF0000FF)],
        ),
      );
      final other = matrix.copyWith(id: 'other');
      final matrixHit = ChartDataHit(
        seriesId: 'matrix',
        pointIndex: 1,
        plotPosition: Offset.zero,
        semanticBounds: Rect.zero,
        point: cells[1],
        formattedValue: '20',
        ordinal: 2,
        count: 4,
      );

      final row = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.mark,
        heatmapExpansion: HeatmapSelectionExpansion.row,
        hits: [matrixHit],
        series: [matrix, other],
      );
      final column = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.mark,
        heatmapExpansion: HeatmapSelectionExpansion.column,
        hits: [matrixHit],
        series: [matrix, other],
      );

      expect(row.pointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 0),
        const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
      });
      expect(column.pointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
        const ChartPointRef(seriesId: 'matrix', pointIndex: 3),
      });
    });

    test('Heatmap expansion excludes cells hidden by a value filter', () {
      final cells = <HeatmapDataPoint>[
        HeatmapDataPoint(x: 0, y: 0, value: 10),
        HeatmapDataPoint(x: 1, y: 0, value: 50),
      ];
      final matrix = HeatmapChartSeries(
        id: 'matrix',
        points: cells,
        colorScale: HeatmapColorScale.sequential(
          colors: const [Color(0xFFFFFFFF), Color(0xFF0000FF)],
        ),
        valueFilter: const HeatmapValueFilter(
          minimumValue: 40,
          maximumValue: 60,
          mode: HeatmapValueFilterMode.hide,
        ),
      );
      final matrixHit = ChartDataHit(
        seriesId: 'matrix',
        pointIndex: 1,
        plotPosition: Offset.zero,
        semanticBounds: Rect.zero,
        point: cells[1],
        formattedValue: '50',
        ordinal: 2,
        count: 2,
      );

      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.mark,
        heatmapExpansion: HeatmapSelectionExpansion.row,
        hits: [matrixHit],
        series: [matrix],
      );

      expect(targets.pointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
      });
    });

    test('mark expands every source row represented by an aggregate hit', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.mark,
        hits: <ChartDataHit>[
          hit(pointIndex: 0, sourcePointIndices: const <int>[0, 2]),
        ],
        series: <ChartSeries>[bar(id: 'first')],
      );

      expect(targets.seriesIds, isEmpty);
      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first', pointIndex: 0),
        const ChartPointRef(seriesId: 'first', pointIndex: 2),
      });
    });

    test('category resolves shared X identity across compatible series', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.category,
        hits: <ChartDataHit>[hit()],
        series: <ChartSeries>[
          bar(id: 'first'),
          bar(id: 'second'),
          const LineChartSeries(id: 'trend', points: sharedPoints),
        ],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first', pointIndex: 1),
        const ChartPointRef(seriesId: 'second', pointIndex: 1),
        const ChartPointRef(seriesId: 'trend', pointIndex: 1),
      });
    });

    test('stack resolves only the same named Bar composition slot', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.categoryStack,
        hits: <ChartDataHit>[hit()],
        series: <ChartSeries>[
          bar(id: 'first', mode: BarLayoutMode.stacked, groupId: 'sales'),
          bar(id: 'second', mode: BarLayoutMode.stacked, groupId: 'sales'),
          bar(id: 'other', mode: BarLayoutMode.stacked, groupId: 'costs'),
          bar(
            id: 'axis',
            mode: BarLayoutMode.stacked,
            groupId: 'sales',
            yAxisId: 'secondary',
          ),
        ],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first', pointIndex: 1),
        const ChartPointRef(seriesId: 'second', pointIndex: 1),
      });
    });

    test('grouped and waterfall bars never imply a multi-series stack', () {
      for (final mode in <BarLayoutMode>[
        BarLayoutMode.grouped,
        BarLayoutMode.waterfall,
      ]) {
        final targets = ChartSelectionResolver.resolve(
          scope: ChartSelectionScope.categoryStack,
          hits: <ChartDataHit>[hit()],
          series: <ChartSeries>[
            bar(id: 'first', mode: mode, groupId: 'same'),
            bar(id: 'second', mode: mode, groupId: 'same'),
          ],
        );

        expect(targets.pointRefs, <ChartPointRef>{
          const ChartPointRef(seriesId: 'first', pointIndex: 1),
        });
      }
    });

    test('stack requires matching orientation', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.categoryStack,
        hits: <ChartDataHit>[hit()],
        series: <ChartSeries>[
          bar(id: 'first', mode: BarLayoutMode.overlaid, groupId: 'same'),
          bar(
            id: 'horizontal',
            mode: BarLayoutMode.overlaid,
            orientation: BarOrientation.horizontal,
            groupId: 'same',
          ),
        ],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first', pointIndex: 1),
      });
    });

    test('series scope returns semantic series identities only', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.wholeSeries,
        hits: <ChartDataHit>[
          hit(),
          hit(seriesId: 'second', pointIndex: 2),
        ],
        series: <ChartSeries>[
          bar(id: 'first'),
          bar(id: 'second'),
        ],
      );

      expect(targets.pointRefs, isEmpty);
      expect(targets.seriesIds, <String>{'first', 'second'});
    });

    test('dual-target scope resolves direct renderer hits as marks only', () {
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.markOrWholeSeries,
        hits: <ChartDataHit>[hit()],
        series: <ChartSeries>[
          bar(id: 'first'),
          bar(id: 'second'),
        ],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first', pointIndex: 1),
      });
      expect(targets.seriesIds, isEmpty);
    });

    test('category crosses compatible concentric radial series', () {
      final outer = DonutChartSeries.fromMap(
        id: 'outer',
        values: const <String, num>{'Subscriptions': 60, 'Services': 40},
      );
      final inner = DonutChartSeries.fromMap(
        id: 'inner',
        values: const <String, num>{'Services': 55, 'Subscriptions': 45},
      );
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.category,
        hits: <ChartDataHit>[
          ChartDataHit(
            seriesId: 'outer',
            pointIndex: 1,
            plotPosition: Offset.zero,
            semanticBounds: Rect.zero,
            point: outer.points[1],
            formattedValue: '40',
            ordinal: 2,
            count: 2,
          ),
        ],
        series: <ChartSeries>[outer, inner],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'outer', pointIndex: 1),
        const ChartPointRef(seriesId: 'inner', pointIndex: 0),
      });
    });

    test('category follows labels across reordered polar series', () {
      final first = PolarColumnChartSeries.fromMap(
        id: 'first-polar',
        values: const <String, num>{'Search': 60, 'Social': 40},
      );
      final second = PolarColumnChartSeries.fromMap(
        id: 'second-polar',
        values: const <String, num>{'Social': 55, 'Search': 45},
      );
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.category,
        hits: <ChartDataHit>[
          ChartDataHit(
            seriesId: 'first-polar',
            pointIndex: 0,
            plotPosition: Offset.zero,
            semanticBounds: Rect.zero,
            point: first.points[0],
            formattedValue: '60',
            ordinal: 1,
            count: 2,
          ),
        ],
        series: <ChartSeries>[first, second],
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'first-polar', pointIndex: 0),
        const ChartPointRef(seriesId: 'second-polar', pointIndex: 1),
      });
    });

    test('stack follows polar category and signed stack identity', () {
      final positive = PolarColumnChartSeries.fromMap(
        id: 'positive',
        values: const <String, num>{'Search': 60, 'Social': 40},
      );
      final matching = PolarColumnChartSeries.fromMap(
        id: 'matching',
        values: const <String, num>{'Social': 55, 'Search': 45},
      );
      final negative = PolarColumnChartSeries.fromMap(
        id: 'negative',
        values: const <String, num>{'Search': -20, 'Social': -10},
      );
      final targets = ChartSelectionResolver.resolve(
        scope: ChartSelectionScope.categoryStack,
        hits: <ChartDataHit>[
          ChartDataHit(
            seriesId: 'positive',
            pointIndex: 0,
            plotPosition: Offset.zero,
            semanticBounds: Rect.zero,
            point: positive.points[0],
            formattedValue: '60',
            ordinal: 1,
            count: 2,
          ),
        ],
        series: <ChartSeries>[positive, matching, negative],
        polarChartConfig: const PolarChartConfig(
          composition: PolarColumnCompositionConfig(
            mode: PolarColumnCompositionMode.stacked,
          ),
        ),
      );

      expect(targets.pointRefs, <ChartPointRef>{
        const ChartPointRef(seriesId: 'positive', pointIndex: 0),
        const ChartPointRef(seriesId: 'matching', pointIndex: 1),
      });
    });
  });
}
