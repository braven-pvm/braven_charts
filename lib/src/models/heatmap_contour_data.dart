// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'chart_data_point.dart';
import 'heatmap_density_data.dart';

/// One scalar sample supplied to a regular Heatmap contour transform.
@immutable
final class HeatmapContourSample {
  HeatmapContourSample({
    required this.xIndex,
    required this.yIndex,
    required this.value,
    Iterable<int> sourceIndices = const [],
    Iterable<String> sourcePointKeys = const [],
  }) : sourceIndices = List.unmodifiable(sourceIndices),
       sourcePointKeys = List.unmodifiable(sourcePointKeys) {
    if (xIndex < 0) {
      throw ArgumentError.value(xIndex, 'xIndex', 'must be non-negative');
    }
    if (yIndex < 0) {
      throw ArgumentError.value(yIndex, 'yIndex', 'must be non-negative');
    }
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
  }

  final int xIndex;
  final int yIndex;
  final double value;
  final List<int> sourceIndices;
  final List<String> sourcePointKeys;
}

/// One interpolated point on a Heatmap contour path.
@immutable
final class HeatmapContourPoint {
  const HeatmapContourPoint({required this.x, required this.y});

  final double x;
  final double y;
}

/// One connected path extracted at a single contour level.
@immutable
final class HeatmapContourPath {
  const HeatmapContourPath({
    required this.id,
    required this.level,
    required this.levelIndex,
    required this.points,
    required this.isClosed,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final String id;
  final double level;
  final int levelIndex;
  final List<HeatmapContourPoint> points;
  final bool isClosed;
  final List<int> sourceIndices;
  final List<String> sourcePointKeys;
}

/// Deterministic Marching Squares contours over a regular Heatmap grid.
@immutable
final class HeatmapContourData {
  factory HeatmapContourData({
    required int xCellCount,
    required int yCellCount,
    required Iterable<HeatmapContourSample> samples,
    required Iterable<double> levels,
  }) {
    if (xCellCount < 2) {
      throw ArgumentError.value(
        xCellCount,
        'xCellCount',
        'must be at least two',
      );
    }
    if (yCellCount < 2) {
      throw ArgumentError.value(
        yCellCount,
        'yCellCount',
        'must be at least two',
      );
    }
    final source = List<HeatmapContourSample>.unmodifiable(samples);
    final expectedCount = xCellCount * yCellCount;
    if (source.length != expectedCount) {
      throw ArgumentError.value(
        source.length,
        'samples',
        'must contain exactly $expectedCount regular-grid samples',
      );
    }
    final grid = List<HeatmapContourSample?>.filled(expectedCount, null);
    for (final sample in source) {
      if (sample.xIndex >= xCellCount || sample.yIndex >= yCellCount) {
        throw ArgumentError.value(
          '(${sample.xIndex}, ${sample.yIndex})',
          'samples',
          'falls outside the declared grid',
        );
      }
      final index = sample.yIndex * xCellCount + sample.xIndex;
      if (grid[index] != null) {
        throw ArgumentError.value(
          '(${sample.xIndex}, ${sample.yIndex})',
          'samples',
          'duplicates an existing grid position',
        );
      }
      grid[index] = sample;
    }
    if (grid.any((sample) => sample == null)) {
      throw ArgumentError.value(
        source.length,
        'samples',
        'must cover every regular-grid position',
      );
    }

    final levelValues = List<double>.unmodifiable(levels);
    if (levelValues.isEmpty) {
      throw ArgumentError.value(levelValues, 'levels', 'must not be empty');
    }
    for (var index = 0; index < levelValues.length; index++) {
      final level = levelValues[index];
      if (!level.isFinite) {
        throw ArgumentError.value(level, 'levels[$index]', 'must be finite');
      }
      if (index > 0 && level <= levelValues[index - 1]) {
        throw ArgumentError.value(
          levelValues,
          'levels',
          'must be strictly increasing',
        );
      }
    }

    final resolvedGrid = List<HeatmapContourSample>.unmodifiable(
      grid.cast<HeatmapContourSample>(),
    );
    return HeatmapContourData._(
      xCellCount: xCellCount,
      yCellCount: yCellCount,
      samples: resolvedGrid,
      levels: levelValues,
      paths: List.unmodifiable([
        for (var levelIndex = 0; levelIndex < levelValues.length; levelIndex++)
          ..._extractLevel(
            grid: resolvedGrid,
            xCellCount: xCellCount,
            yCellCount: yCellCount,
            level: levelValues[levelIndex],
            levelIndex: levelIndex,
          ),
      ]),
    );
  }

  /// Extracts contours directly from a canonical density raster.
  factory HeatmapContourData.fromDensity(
    HeatmapDensityData density, {
    required Iterable<double> levels,
    HeatmapDensityValueMode valueMode = HeatmapDensityValueMode.relative,
  }) => HeatmapContourData(
    xCellCount: density.xAxis.cellCount,
    yCellCount: density.yAxis.cellCount,
    levels: levels,
    samples: [
      for (final cell in density.cells)
        HeatmapContourSample(
          xIndex: cell.xIndex,
          yIndex: cell.yIndex,
          value: switch (valueMode) {
            HeatmapDensityValueMode.density => cell.density,
            HeatmapDensityValueMode.relative => cell.relativeDensity,
          },
          sourceIndices: cell.sourceIndices,
          sourcePointKeys: cell.sourcePointKeys,
        ),
    ],
  );

  const HeatmapContourData._({
    required this.xCellCount,
    required this.yCellCount,
    required this.samples,
    required this.levels,
    required this.paths,
  });

  final int xCellCount;
  final int yCellCount;
  final List<HeatmapContourSample> samples;
  final List<double> levels;
  final List<HeatmapContourPath> paths;

  /// Maps one extracted path to ordinary Cartesian chart points.
  List<ChartDataPoint> chartPointsFor(HeatmapContourPath path) =>
      List.unmodifiable([
        for (var index = 0; index < path.points.length; index++)
          ChartDataPoint(
            x: path.points[index].x,
            y: path.points[index].y,
            pointKey: '${path.id}-point-$index',
            label: 'Contour ${(path.level * 100).toStringAsFixed(0)}%',
            metadata: {
              'densityContourLevel': path.level,
              'densityContourLevelIndex': path.levelIndex,
              'densityContourPathId': path.id,
              'densityContourClosed': path.isClosed,
              'densityContourSourceIndices': path.sourceIndices,
              'densityContourSourcePointKeys': path.sourcePointKeys,
            },
          ),
      ]);

  static List<HeatmapContourPath> _extractLevel({
    required List<HeatmapContourSample> grid,
    required int xCellCount,
    required int yCellCount,
    required double level,
    required int levelIndex,
  }) {
    HeatmapContourSample sampleAt(int x, int y) => grid[y * xCellCount + x];

    final segments = <_ContourSegment>[];
    for (var y = 0; y < yCellCount - 1; y++) {
      for (var x = 0; x < xCellCount - 1; x++) {
        final bottomLeft = sampleAt(x, y);
        final bottomRight = sampleAt(x + 1, y);
        final topRight = sampleAt(x + 1, y + 1);
        final topLeft = sampleAt(x, y + 1);
        final corners = [bottomLeft, bottomRight, topRight, topLeft];
        var squareCase = 0;
        if (bottomLeft.value >= level) squareCase |= 1;
        if (bottomRight.value >= level) squareCase |= 2;
        if (topRight.value >= level) squareCase |= 4;
        if (topLeft.value >= level) squareCase |= 8;
        if (squareCase == 0 || squareCase == 15) continue;

        HeatmapContourPoint edgePoint(int edge) {
          final (first, second) = switch (edge) {
            0 => (bottomLeft, bottomRight),
            1 => (bottomRight, topRight),
            2 => (topLeft, topRight),
            3 => (bottomLeft, topLeft),
            _ => throw StateError('Unknown contour edge $edge'),
          };
          final denominator = second.value - first.value;
          final fraction = denominator.abs() <= 1e-15
              ? 0.5
              : ((level - first.value) / denominator).clamp(0.0, 1.0);
          return HeatmapContourPoint(
            x: first.xIndex + (second.xIndex - first.xIndex) * fraction,
            y: first.yIndex + (second.yIndex - first.yIndex) * fraction,
          );
        }

        final sourceIndices = <int>{};
        final sourcePointKeys = <String>{};
        for (final corner in corners) {
          sourceIndices.addAll(corner.sourceIndices);
          sourcePointKeys.addAll(corner.sourcePointKeys);
        }
        void add(int firstEdge, int secondEdge) {
          segments.add(
            _ContourSegment(
              start: edgePoint(firstEdge),
              end: edgePoint(secondEdge),
              sourceIndices: sourceIndices,
              sourcePointKeys: sourcePointKeys,
            ),
          );
        }

        switch (squareCase) {
          case 1:
          case 14:
            add(3, 0);
          case 2:
          case 13:
            add(0, 1);
          case 3:
          case 12:
            add(3, 1);
          case 4:
          case 11:
            add(1, 2);
          case 5:
          case 10:
            final determinant =
                (bottomLeft.value - level) * (topRight.value - level) -
                (bottomRight.value - level) * (topLeft.value - level);
            final connectFirstDiagonal =
                (squareCase == 5 && determinant >= 0) ||
                (squareCase == 10 && determinant < 0);
            if (connectFirstDiagonal) {
              add(3, 2);
              add(0, 1);
            } else {
              add(3, 0);
              add(2, 1);
            }
          case 6:
          case 9:
            add(0, 2);
          case 7:
          case 8:
            add(3, 2);
        }
      }
    }
    return _stitchSegments(segments, level: level, levelIndex: levelIndex);
  }

  static List<HeatmapContourPath> _stitchSegments(
    List<_ContourSegment> segments, {
    required double level,
    required int levelIndex,
  }) {
    if (segments.isEmpty) return const [];
    final adjacency = <String, List<int>>{};
    for (var index = 0; index < segments.length; index++) {
      adjacency
          .putIfAbsent(_pointKey(segments[index].start), () => [])
          .add(index);
      adjacency
          .putIfAbsent(_pointKey(segments[index].end), () => [])
          .add(index);
    }
    final used = List<bool>.filled(segments.length, false);
    final rawPaths = <_MutableContourPath>[];

    void consume(int seedIndex, {String? preferredStartKey}) {
      if (used[seedIndex]) return;
      final seed = segments[seedIndex];
      final startFromEnd = preferredStartKey == _pointKey(seed.end);
      final points = <HeatmapContourPoint>[
        startFromEnd ? seed.end : seed.start,
        startFromEnd ? seed.start : seed.end,
      ];
      final sourceIndices = <int>{...seed.sourceIndices};
      final sourcePointKeys = <String>{...seed.sourcePointKeys};
      used[seedIndex] = true;
      while (true) {
        final endKey = _pointKey(points.last);
        final nextIndex = (adjacency[endKey] ?? const <int>[])
            .cast<int?>()
            .firstWhere(
              (candidate) => candidate != null && !used[candidate],
              orElse: () => null,
            );
        if (nextIndex == null) break;
        final next = segments[nextIndex];
        used[nextIndex] = true;
        points.add(_pointKey(next.start) == endKey ? next.end : next.start);
        sourceIndices.addAll(next.sourceIndices);
        sourcePointKeys.addAll(next.sourcePointKeys);
      }
      rawPaths.add(
        _MutableContourPath(
          points: points,
          sourceIndices: sourceIndices.toList()..sort(),
          sourcePointKeys: sourcePointKeys.toList()..sort(),
        ),
      );
    }

    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      final startKey = _pointKey(segment.start);
      final endKey = _pointKey(segment.end);
      if ((adjacency[startKey]?.length ?? 0) == 1) {
        consume(index, preferredStartKey: startKey);
      } else if ((adjacency[endKey]?.length ?? 0) == 1) {
        consume(index, preferredStartKey: endKey);
      }
    }
    for (var index = 0; index < segments.length; index++) {
      consume(index);
    }
    rawPaths.sort((first, second) {
      final x = first.points.first.x.compareTo(second.points.first.x);
      if (x != 0) return x;
      final y = first.points.first.y.compareTo(second.points.first.y);
      if (y != 0) return y;
      return first.points.length.compareTo(second.points.length);
    });
    return List.unmodifiable([
      for (var index = 0; index < rawPaths.length; index++)
        HeatmapContourPath(
          id: 'contour-$levelIndex-path-$index',
          level: level,
          levelIndex: levelIndex,
          points: List.unmodifiable(rawPaths[index].points),
          isClosed:
              _pointKey(rawPaths[index].points.first) ==
              _pointKey(rawPaths[index].points.last),
          sourceIndices: List.unmodifiable(rawPaths[index].sourceIndices),
          sourcePointKeys: List.unmodifiable(rawPaths[index].sourcePointKeys),
        ),
    ]);
  }

  static String _pointKey(HeatmapContourPoint point) =>
      '${(point.x * 1000000000).round()}:${(point.y * 1000000000).round()}';
}

final class _ContourSegment {
  const _ContourSegment({
    required this.start,
    required this.end,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final HeatmapContourPoint start;
  final HeatmapContourPoint end;
  final Set<int> sourceIndices;
  final Set<String> sourcePointKeys;
}

final class _MutableContourPath {
  const _MutableContourPath({
    required this.points,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final List<HeatmapContourPoint> points;
  final List<int> sourceIndices;
  final List<String> sourcePointKeys;
}
