// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'heatmap_data_point.dart';

/// Kernel used to estimate a regular Heatmap density raster.
enum HeatmapDensityKernel {
  /// Smooth Gaussian product kernel with explicit finite truncation.
  gaussian,

  /// Compact Epanechnikov product kernel with natural unit support.
  epanechnikov,
}

/// Value written to canonical Heatmap cells.
enum HeatmapDensityValueMode {
  /// Probability density in source-domain units.
  density,

  /// Density divided by the maximum sampled density.
  relative,
}

/// One raw observation supplied to a Heatmap density transform.
@immutable
final class HeatmapDensityObservation {
  HeatmapDensityObservation({
    required this.x,
    required this.y,
    this.weight = 1,
    this.pointKey,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata == null ? null : Map.unmodifiable(metadata) {
    if (!x.isFinite) {
      throw ArgumentError.value(x, 'x', 'must be finite');
    }
    if (!y.isFinite) {
      throw ArgumentError.value(y, 'y', 'must be finite');
    }
    if (!weight.isFinite || weight < 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'must be finite and non-negative',
      );
    }
    if (pointKey != null && pointKey!.isEmpty) {
      throw ArgumentError.value(pointKey, 'pointKey', 'must not be empty');
    }
  }

  final double x;
  final double y;
  final double weight;
  final String? pointKey;
  final Map<String, dynamic>? metadata;
}

/// Explicit regular sampling domain for one density-raster axis.
@immutable
final class HeatmapDensityAxis {
  HeatmapDensityAxis({
    required this.minimum,
    required this.maximum,
    required this.cellCount,
    List<String>? labels,
  }) : labels = List.unmodifiable(
         labels ??
             [
               for (var index = 0; index < cellCount; index++)
                 _format(centerFor(index, minimum, maximum, cellCount)),
             ],
       ) {
    if (!minimum.isFinite) {
      throw ArgumentError.value(minimum, 'minimum', 'must be finite');
    }
    if (!maximum.isFinite || maximum <= minimum) {
      throw ArgumentError.value(
        maximum,
        'maximum',
        'must be finite and greater than minimum',
      );
    }
    if (cellCount <= 0) {
      throw ArgumentError.value(cellCount, 'cellCount', 'must be positive');
    }
    if (this.labels.length != cellCount) {
      throw ArgumentError.value(
        labels,
        'labels',
        'must contain exactly $cellCount entries',
      );
    }
    for (var index = 0; index < this.labels.length; index++) {
      if (this.labels[index].isEmpty) {
        throw ArgumentError.value(
          this.labels[index],
          'labels[$index]',
          'must not be empty',
        );
      }
    }
  }

  final double minimum;
  final double maximum;
  final int cellCount;
  final List<String> labels;

  double get cellExtent => (maximum - minimum) / cellCount;

  double centerAt(int index) {
    RangeError.checkValidIndex(index, labels, 'index');
    return centerFor(index, minimum, maximum, cellCount);
  }

  double lowerBoundAt(int index) => centerAt(index) - cellExtent / 2;
  double upperBoundAt(int index) => centerAt(index) + cellExtent / 2;

  static double centerFor(
    int index,
    double minimum,
    double maximum,
    int cellCount,
  ) => minimum + (index + 0.5) * ((maximum - minimum) / cellCount);

  static String _format(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    if (value.abs() < 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(1);
  }
}

/// One evaluated cell in a density raster.
@immutable
final class HeatmapDensityCell {
  const HeatmapDensityCell({
    required this.xIndex,
    required this.yIndex,
    required this.xCenter,
    required this.yCenter,
    required this.density,
    required this.relativeDensity,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final int xIndex;
  final int yIndex;
  final double xCenter;
  final double yCenter;
  final double density;
  final double relativeDensity;
  final List<int> sourceIndices;
  final List<String> sourcePointKeys;
}

/// Deterministic data-domain density raster prepared for a native Heatmap.
@immutable
final class HeatmapDensityData {
  factory HeatmapDensityData({
    required Iterable<HeatmapDensityObservation> observations,
    required HeatmapDensityAxis xAxis,
    required HeatmapDensityAxis yAxis,
    required double bandwidthX,
    required double bandwidthY,
    HeatmapDensityKernel kernel = HeatmapDensityKernel.gaussian,
    double gaussianTruncationRadius = 3,
  }) {
    if (!bandwidthX.isFinite || bandwidthX <= 0) {
      throw ArgumentError.value(
        bandwidthX,
        'bandwidthX',
        'must be finite and positive',
      );
    }
    if (!bandwidthY.isFinite || bandwidthY <= 0) {
      throw ArgumentError.value(
        bandwidthY,
        'bandwidthY',
        'must be finite and positive',
      );
    }
    if (!gaussianTruncationRadius.isFinite || gaussianTruncationRadius <= 0) {
      throw ArgumentError.value(
        gaussianTruncationRadius,
        'gaussianTruncationRadius',
        'must be finite and positive',
      );
    }

    final source = List<HeatmapDensityObservation>.unmodifiable(observations);
    final pointKeys = <String>{};
    for (var index = 0; index < source.length; index++) {
      final pointKey = source[index].pointKey;
      if (pointKey != null && !pointKeys.add(pointKey)) {
        throw ArgumentError.value(
          pointKey,
          'observations[$index].pointKey',
          'duplicates an existing raw observation identity',
        );
      }
    }
    final totalWeight = source.fold(
      0.0,
      (sum, observation) => sum + observation.weight,
    );
    final mutable = <_MutableHeatmapDensityCell>[];
    var maximumDensity = 0.0;
    for (var yIndex = 0; yIndex < yAxis.cellCount; yIndex++) {
      final yCenter = yAxis.centerAt(yIndex);
      for (var xIndex = 0; xIndex < xAxis.cellCount; xIndex++) {
        final xCenter = xAxis.centerAt(xIndex);
        var weightedKernelSum = 0.0;
        final sourceIndices = <int>[];
        final sourcePointKeys = <String>[];
        for (var sourceIndex = 0; sourceIndex < source.length; sourceIndex++) {
          final observation = source[sourceIndex];
          final xKernel = _kernelValue(
            (xCenter - observation.x) / bandwidthX,
            kernel: kernel,
            gaussianTruncationRadius: gaussianTruncationRadius,
          );
          if (xKernel == 0) continue;
          final yKernel = _kernelValue(
            (yCenter - observation.y) / bandwidthY,
            kernel: kernel,
            gaussianTruncationRadius: gaussianTruncationRadius,
          );
          if (yKernel == 0) continue;
          weightedKernelSum += observation.weight * xKernel * yKernel;
          sourceIndices.add(sourceIndex);
          final pointKey = observation.pointKey;
          if (pointKey != null) sourcePointKeys.add(pointKey);
        }
        final density = totalWeight == 0
            ? 0.0
            : weightedKernelSum / (totalWeight * bandwidthX * bandwidthY);
        if (density > maximumDensity) maximumDensity = density;
        mutable.add(
          _MutableHeatmapDensityCell(
            xIndex: xIndex,
            yIndex: yIndex,
            xCenter: xCenter,
            yCenter: yCenter,
            density: density,
            sourceIndices: sourceIndices,
            sourcePointKeys: sourcePointKeys,
          ),
        );
      }
    }

    return HeatmapDensityData._(
      observations: source,
      xAxis: xAxis,
      yAxis: yAxis,
      bandwidthX: bandwidthX,
      bandwidthY: bandwidthY,
      kernel: kernel,
      gaussianTruncationRadius: gaussianTruncationRadius,
      totalWeight: totalWeight,
      maximumDensity: maximumDensity,
      cells: List.unmodifiable([
        for (final cell in mutable)
          HeatmapDensityCell(
            xIndex: cell.xIndex,
            yIndex: cell.yIndex,
            xCenter: cell.xCenter,
            yCenter: cell.yCenter,
            density: cell.density,
            relativeDensity: maximumDensity == 0
                ? 0
                : cell.density / maximumDensity,
            sourceIndices: List.unmodifiable(cell.sourceIndices),
            sourcePointKeys: List.unmodifiable(cell.sourcePointKeys),
          ),
      ]),
    );
  }

  const HeatmapDensityData._({
    required this.observations,
    required this.xAxis,
    required this.yAxis,
    required this.bandwidthX,
    required this.bandwidthY,
    required this.kernel,
    required this.gaussianTruncationRadius,
    required this.totalWeight,
    required this.maximumDensity,
    required this.cells,
  });

  final List<HeatmapDensityObservation> observations;
  final HeatmapDensityAxis xAxis;
  final HeatmapDensityAxis yAxis;
  final double bandwidthX;
  final double bandwidthY;
  final HeatmapDensityKernel kernel;
  final double gaussianTruncationRadius;
  final double totalWeight;
  final double maximumDensity;
  final List<HeatmapDensityCell> cells;

  HeatmapDensityCell cellAt({required int xIndex, required int yIndex}) {
    RangeError.checkValidIndex(xIndex, xAxis.labels, 'xIndex');
    RangeError.checkValidIndex(yIndex, yAxis.labels, 'yIndex');
    return cells[yIndex * xAxis.cellCount + xIndex];
  }

  /// Creates canonical Heatmap cells in row-major order.
  List<HeatmapDataPoint> cellsFor({
    HeatmapDensityValueMode valueMode = HeatmapDensityValueMode.relative,
  }) => List.unmodifiable([
    for (final cell in cells)
      HeatmapDataPoint(
        x: cell.xIndex.toDouble(),
        y: cell.yIndex.toDouble(),
        value: switch (valueMode) {
          HeatmapDensityValueMode.density => cell.density,
          HeatmapDensityValueMode.relative => cell.relativeDensity,
        },
        pointKey: 'density-${cell.yIndex}-${cell.xIndex}',
        label: '${yAxis.labels[cell.yIndex]} · ${xAxis.labels[cell.xIndex]}',
        metadata: {
          'densityXLowerBound': xAxis.lowerBoundAt(cell.xIndex),
          'densityXUpperBound': xAxis.upperBoundAt(cell.xIndex),
          'densityYLowerBound': yAxis.lowerBoundAt(cell.yIndex),
          'densityYUpperBound': yAxis.upperBoundAt(cell.yIndex),
          'densityXCenter': cell.xCenter,
          'densityYCenter': cell.yCenter,
          'density': cell.density,
          'relativeDensity': cell.relativeDensity,
          'densityKernel': kernel.name,
          'densityBandwidthX': bandwidthX,
          'densityBandwidthY': bandwidthY,
          'densitySourceIndices': cell.sourceIndices,
          'densitySourcePointKeys': cell.sourcePointKeys,
        },
      ),
  ]);

  static double _kernelValue(
    double distance, {
    required HeatmapDensityKernel kernel,
    required double gaussianTruncationRadius,
  }) {
    final absoluteDistance = distance.abs();
    return switch (kernel) {
      HeatmapDensityKernel.gaussian =>
        absoluteDistance > gaussianTruncationRadius
            ? 0
            : math.exp(-0.5 * distance * distance) / math.sqrt(2 * math.pi),
      HeatmapDensityKernel.epanechnikov =>
        absoluteDistance > 1 ? 0 : 0.75 * (1 - distance * distance),
    };
  }
}

final class _MutableHeatmapDensityCell {
  const _MutableHeatmapDensityCell({
    required this.xIndex,
    required this.yIndex,
    required this.xCenter,
    required this.yCenter,
    required this.density,
    required this.sourceIndices,
    required this.sourcePointKeys,
  });

  final int xIndex;
  final int yIndex;
  final double xCenter;
  final double yCenter;
  final double density;
  final List<int> sourceIndices;
  final List<String> sourcePointKeys;
}
