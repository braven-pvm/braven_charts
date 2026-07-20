// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../models/scatter_render_config.dart';
import 'scatter_geometry.dart';

/// One relative-density isoline produced from a Scatter viewport.
class ScatterDensityContour {
  const ScatterDensityContour({
    required this.relativeDensity,
    required this.path,
    required this.segmentCount,
  });

  /// Threshold in the inclusive normalized density domain 0–1.
  final double relativeDensity;

  /// Disconnected line segments comprising this isoline.
  final Path path;

  /// Number of line segments in [path].
  final int segmentCount;

  Rect get paintBounds => path.getBounds();
}

/// Deterministic screen-space density field and its contour family.
class ScatterDensityLayout {
  const ScatterDensityLayout({
    required this.contours,
    required this.normalizedValues,
    required this.columns,
    required this.rows,
    required this.gridCellSize,
    required this.plotSize,
    required this.maximumDensity,
    required this.sourcePointCount,
  });

  final List<ScatterDensityContour> contours;
  final Float64List normalizedValues;
  final int columns;
  final int rows;
  final double gridCellSize;
  final Size plotSize;
  final double maximumDensity;
  final int sourcePointCount;

  bool get isEmpty => sourcePointCount == 0 || maximumDensity <= 0;

  /// Bilinearly samples relative density at a plot-local position.
  double relativeDensityAt(Offset position) {
    if (isEmpty ||
        position.dx < 0 ||
        position.dy < 0 ||
        position.dx > plotSize.width ||
        position.dy > plotSize.height) {
      return 0;
    }
    final gridX = (position.dx / gridCellSize).clamp(0, columns - 1.0);
    final gridY = (position.dy / gridCellSize).clamp(0, rows - 1.0);
    final left = gridX.floor();
    final top = gridY.floor();
    final right = math.min(columns - 1, left + 1);
    final bottom = math.min(rows - 1, top + 1);
    final xFraction = gridX - left;
    final yFraction = gridY - top;
    final topValue =
        _valueAt(left, top) * (1 - xFraction) +
        _valueAt(right, top) * xFraction;
    final bottomValue =
        _valueAt(left, bottom) * (1 - xFraction) +
        _valueAt(right, bottom) * xFraction;
    return topValue * (1 - yFraction) + bottomValue * yFraction;
  }

  /// Plot-local sample cell around [position], clipped to the plot.
  Rect sampleBoundsAt(Offset position) {
    final x = (position.dx / gridCellSize).floor() * gridCellSize;
    final y = (position.dy / gridCellSize).floor() * gridCellSize;
    return Rect.fromLTRB(
      x.clamp(0, plotSize.width),
      y.clamp(0, plotSize.height),
      (x + gridCellSize).clamp(0, plotSize.width),
      (y + gridCellSize).clamp(0, plotSize.height),
    );
  }

  double _valueAt(int column, int row) =>
      normalizedValues[row * columns + column];
}

/// Linear-time histogram plus separable Gaussian smoothing and marching squares.
abstract final class ScatterDensityEngine {
  static ScatterDensityLayout layout({
    required List<ScatterPointGeometry> geometries,
    required Size plotSize,
    required ScatterDensityConfig config,
  }) {
    final columns = math.max(
      2,
      (plotSize.width / config.gridCellSize).ceil() + 1,
    );
    final rows = math.max(
      2,
      (plotSize.height / config.gridCellSize).ceil() + 1,
    );
    final sampleCount = columns * rows;
    if (geometries.isEmpty || plotSize.isEmpty) {
      return ScatterDensityLayout(
        contours: const [],
        normalizedValues: Float64List(sampleCount),
        columns: columns,
        rows: rows,
        gridCellSize: config.gridCellSize,
        plotSize: plotSize,
        maximumDensity: 0,
        sourcePointCount: geometries.length,
      );
    }

    final histogram = Float64List(sampleCount);
    for (final geometry in geometries) {
      final column = (geometry.center.dx / config.gridCellSize).round().clamp(
        0,
        columns - 1,
      );
      final row = (geometry.center.dy / config.gridCellSize).round().clamp(
        0,
        rows - 1,
      );
      histogram[row * columns + column]++;
    }

    final sigma = config.bandwidth / config.gridCellSize;
    final radius = math.max(1, (sigma * 3).ceil());
    final kernel = Float64List(radius * 2 + 1);
    for (var offset = -radius; offset <= radius; offset++) {
      kernel[offset + radius] = math.exp(
        -(offset * offset) / (2 * sigma * sigma),
      );
    }
    final horizontal = _convolveHorizontal(
      histogram,
      columns: columns,
      rows: rows,
      kernel: kernel,
      radius: radius,
    );
    final density = _convolveVertical(
      horizontal,
      columns: columns,
      rows: rows,
      kernel: kernel,
      radius: radius,
    );
    var maximumDensity = 0.0;
    for (final value in density) {
      maximumDensity = math.max(maximumDensity, value);
    }
    final normalized = Float64List(sampleCount);
    if (maximumDensity > 0) {
      for (var index = 0; index < sampleCount; index++) {
        normalized[index] = density[index] / maximumDensity;
      }
    }

    final contours = <ScatterDensityContour>[];
    for (var index = 0; index < config.contourCount; index++) {
      final threshold =
          config.minimumDensity +
          (1 - config.minimumDensity) * index / config.contourCount;
      final contour = _traceContour(
        normalized,
        columns: columns,
        rows: rows,
        cellSize: config.gridCellSize,
        plotSize: plotSize,
        threshold: threshold,
      );
      if (contour.segmentCount > 0) contours.add(contour);
    }
    return ScatterDensityLayout(
      contours: List.unmodifiable(contours),
      normalizedValues: normalized,
      columns: columns,
      rows: rows,
      gridCellSize: config.gridCellSize,
      plotSize: plotSize,
      maximumDensity: maximumDensity,
      sourcePointCount: geometries.length,
    );
  }

  static Float64List _convolveHorizontal(
    Float64List source, {
    required int columns,
    required int rows,
    required Float64List kernel,
    required int radius,
  }) {
    final result = Float64List(source.length);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        var weighted = 0.0;
        var weight = 0.0;
        for (var offset = -radius; offset <= radius; offset++) {
          final sourceColumn = column + offset;
          if (sourceColumn < 0 || sourceColumn >= columns) continue;
          final kernelWeight = kernel[offset + radius];
          weighted += source[row * columns + sourceColumn] * kernelWeight;
          weight += kernelWeight;
        }
        result[row * columns + column] = weight == 0 ? 0 : weighted / weight;
      }
    }
    return result;
  }

  static Float64List _convolveVertical(
    Float64List source, {
    required int columns,
    required int rows,
    required Float64List kernel,
    required int radius,
  }) {
    final result = Float64List(source.length);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        var weighted = 0.0;
        var weight = 0.0;
        for (var offset = -radius; offset <= radius; offset++) {
          final sourceRow = row + offset;
          if (sourceRow < 0 || sourceRow >= rows) continue;
          final kernelWeight = kernel[offset + radius];
          weighted += source[sourceRow * columns + column] * kernelWeight;
          weight += kernelWeight;
        }
        result[row * columns + column] = weight == 0 ? 0 : weighted / weight;
      }
    }
    return result;
  }

  static ScatterDensityContour _traceContour(
    Float64List values, {
    required int columns,
    required int rows,
    required double cellSize,
    required Size plotSize,
    required double threshold,
  }) {
    final path = Path();
    var segmentCount = 0;
    double valueAt(int column, int row) => values[row * columns + column];
    for (var row = 0; row < rows - 1; row++) {
      for (var column = 0; column < columns - 1; column++) {
        final topLeft = valueAt(column, row);
        final topRight = valueAt(column + 1, row);
        final bottomRight = valueAt(column + 1, row + 1);
        final bottomLeft = valueAt(column, row + 1);
        final state =
            (topLeft >= threshold ? 8 : 0) |
            (topRight >= threshold ? 4 : 0) |
            (bottomRight >= threshold ? 2 : 0) |
            (bottomLeft >= threshold ? 1 : 0);
        if (state == 0 || state == 15) continue;
        final left = column * cellSize;
        final top = row * cellSize;
        final topPoint = Offset(
          left + cellSize * _fraction(topLeft, topRight, threshold),
          top,
        );
        final rightPoint = Offset(
          left + cellSize,
          top + cellSize * _fraction(topRight, bottomRight, threshold),
        );
        final bottomPoint = Offset(
          left + cellSize * _fraction(bottomLeft, bottomRight, threshold),
          top + cellSize,
        );
        final leftPoint = Offset(
          left,
          top + cellSize * _fraction(topLeft, bottomLeft, threshold),
        );
        void add(Offset start, Offset end) {
          path
            ..moveTo(
              start.dx.clamp(0, plotSize.width),
              start.dy.clamp(0, plotSize.height),
            )
            ..lineTo(
              end.dx.clamp(0, plotSize.width),
              end.dy.clamp(0, plotSize.height),
            );
          segmentCount++;
        }

        switch (state) {
          case 1:
          case 14:
            add(leftPoint, bottomPoint);
          case 2:
          case 13:
            add(bottomPoint, rightPoint);
          case 3:
          case 12:
            add(leftPoint, rightPoint);
          case 4:
          case 11:
            add(topPoint, rightPoint);
          case 5:
            add(topPoint, leftPoint);
            add(bottomPoint, rightPoint);
          case 6:
          case 9:
            add(topPoint, bottomPoint);
          case 7:
          case 8:
            add(topPoint, leftPoint);
          case 10:
            add(leftPoint, bottomPoint);
            add(topPoint, rightPoint);
        }
      }
    }
    return ScatterDensityContour(
      relativeDensity: threshold,
      path: path,
      segmentCount: segmentCount,
    );
  }

  static double _fraction(double start, double end, double threshold) {
    final delta = end - start;
    if (delta.abs() < 0.0000001) return 0.5;
    return ((threshold - start) / delta).clamp(0, 1).toDouble();
  }
}
