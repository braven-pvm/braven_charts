// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../models/chart_data_point.dart';
import '../models/scatter_render_config.dart';
import 'scatter_geometry.dart';

/// One deterministic rectangular or hexagonal aggregation of observations.
class ScatterBinGeometry {
  ScatterBinGeometry({
    required List<int> sourcePointIndices,
    required this.center,
    required this.path,
    required this.dataCentroid,
    required this.dataXRange,
    required this.dataYRange,
    required this.aggregateValue,
    required this.aggregateSampleCount,
    required this.normalizedIntensity,
  }) : assert(sourcePointIndices.isNotEmpty),
       assert(normalizedIntensity >= 0 && normalizedIntensity <= 1),
       sourcePointIndices = List<int>.unmodifiable(sourcePointIndices),
       paintBounds = path.getBounds();

  /// Raw source identities represented by this rendered bin.
  final List<int> sourcePointIndices;

  /// Stable grid center in plot-local logical pixels.
  final Offset center;

  /// Exact visible rectangular or hexagonal silhouette.
  final Path path;

  /// Mean source coordinate represented by the bin.
  final Offset dataCentroid;

  /// Minimum and maximum source X values represented by the bin.
  final ({double minimum, double maximum}) dataXRange;

  /// Minimum and maximum source Y values represented by the bin.
  final ({double minimum, double maximum}) dataYRange;

  /// Resolved statistic represented by opacity and optional on-bin text.
  final double aggregateValue;

  /// Source values contributing to [aggregateValue].
  ///
  /// This equals [pointCount] for count/proportion and may be smaller when an
  /// optional value source is absent on some observations.
  final int aggregateSampleCount;

  /// Square-root normalized count used by the default count presentation.
  final double normalizedIntensity;

  /// Cached plot-local paint bounds for culling and indexed hits.
  final Rect paintBounds;

  int get pointCount => sourcePointIndices.length;
  int get representativePointIndex => sourcePointIndices.first;

  bool contains(Offset position, {double hitSlop = 0}) {
    if (path.contains(position)) return true;
    if (hitSlop <= 0 || !paintBounds.inflate(hitSlop).contains(position)) {
      return false;
    }
    return (position - center).distance <=
        math.max(paintBounds.width, paintBounds.height) / 2 + hitSlop;
  }
}

/// Result of one viewport-specific 2D binning pass.
class ScatterBinLayout {
  const ScatterBinLayout({
    required this.bins,
    required this.sourcePointCount,
    required this.filteredPointCount,
    this.aggregateMinimum,
    this.aggregateMaximum,
  });

  final List<ScatterBinGeometry> bins;
  final int sourcePointCount;
  final int filteredPointCount;
  final double? aggregateMinimum;
  final double? aggregateMaximum;

  int get renderedMarkerCount => bins.length;
  int get binnedPointCount =>
      bins.fold(0, (total, bin) => total + bin.sourcePointIndices.length);
}

/// Linear-time deterministic plot-space rectangular and hexagonal binning.
abstract final class ScatterBinEngine {
  static ScatterBinLayout layout({
    required List<ScatterPointGeometry> geometries,
    required ScatterRenderMode mode,
    required ScatterBinConfig config,
  }) {
    assert(
      mode == ScatterRenderMode.rectangularBins ||
          mode == ScatterRenderMode.hexbin,
    );
    if (geometries.isEmpty) {
      return const ScatterBinLayout(
        bins: [],
        sourcePointCount: 0,
        filteredPointCount: 0,
      );
    }

    final cells = <(int, int), List<ScatterPointGeometry>>{};
    for (final geometry in geometries) {
      final key = mode == ScatterRenderMode.hexbin
          ? _hexKey(geometry.center, config.cellSize / 2)
          : (
              (geometry.center.dx / config.cellSize).floor(),
              (geometry.center.dy / config.cellSize).floor(),
            );
      cells.putIfAbsent(key, () => []).add(geometry);
    }

    final orderedKeys = cells.keys.toList()
      ..sort((left, right) {
        final row = left.$2.compareTo(right.$2);
        return row != 0 ? row : left.$1.compareTo(right.$1);
      });
    final candidates = <_ScatterBinCandidate>[];
    var filteredPointCount = 0;
    var aggregateMinimum = double.infinity;
    var aggregateMaximum = double.negativeInfinity;
    for (final key in orderedKeys) {
      final members = cells[key]!;
      if (members.length < config.minimumPointCount) {
        filteredPointCount += members.length;
        continue;
      }
      final aggregate = _aggregate(
        members,
        config,
        totalPointCount: geometries.length,
      );
      if (aggregate == null) {
        filteredPointCount += members.length;
        continue;
      }
      final center = mode == ScatterRenderMode.hexbin
          ? _hexCenter(key, config.cellSize / 2)
          : Offset(
              (key.$1 + 0.5) * config.cellSize,
              (key.$2 + 0.5) * config.cellSize,
            );
      final path = mode == ScatterRenderMode.hexbin
          ? _hexPath(center, config.cellSize / 2, config.gap)
          : _rectangularPath(center, config.cellSize, config.gap);
      var dataX = 0.0;
      var dataY = 0.0;
      var minimumX = double.infinity;
      var maximumX = double.negativeInfinity;
      var minimumY = double.infinity;
      var maximumY = double.negativeInfinity;
      final sourceIndices = <int>[];
      for (final member in members) {
        dataX += member.point.x;
        dataY += member.point.y;
        minimumX = math.min(minimumX, member.point.x);
        maximumX = math.max(maximumX, member.point.x);
        minimumY = math.min(minimumY, member.point.y);
        maximumY = math.max(maximumY, member.point.y);
        sourceIndices.add(member.pointIndex);
      }
      sourceIndices.sort();
      aggregateMinimum = math.min(aggregateMinimum, aggregate.value);
      aggregateMaximum = math.max(aggregateMaximum, aggregate.value);
      candidates.add(
        _ScatterBinCandidate(
          sourcePointIndices: sourceIndices,
          center: center,
          path: path,
          dataCentroid: Offset(dataX / members.length, dataY / members.length),
          dataXRange: (minimum: minimumX, maximum: maximumX),
          dataYRange: (minimum: minimumY, maximum: maximumY),
          aggregateValue: aggregate.value,
          aggregateSampleCount: aggregate.sampleCount,
        ),
      );
    }

    final bins = <ScatterBinGeometry>[
      for (final candidate in candidates)
        ScatterBinGeometry(
          sourcePointIndices: candidate.sourcePointIndices,
          center: candidate.center,
          path: candidate.path,
          dataCentroid: candidate.dataCentroid,
          dataXRange: candidate.dataXRange,
          dataYRange: candidate.dataYRange,
          aggregateValue: candidate.aggregateValue,
          aggregateSampleCount: candidate.aggregateSampleCount,
          normalizedIntensity: _normalizedIntensity(
            candidate.aggregateValue,
            minimum: aggregateMinimum,
            maximum: aggregateMaximum,
            useSquareRoot:
                config.aggregate == ScatterBinAggregate.count ||
                config.aggregate == ScatterBinAggregate.proportion,
          ),
        ),
    ];

    return ScatterBinLayout(
      bins: List.unmodifiable(bins),
      sourcePointCount: geometries.length,
      filteredPointCount: filteredPointCount,
      aggregateMinimum: bins.isEmpty ? null : aggregateMinimum,
      aggregateMaximum: bins.isEmpty ? null : aggregateMaximum,
    );
  }

  static ChartDataPoint centroidPoint(ScatterBinGeometry bin) => ChartDataPoint(
    x: bin.dataCentroid.dx,
    y: bin.dataCentroid.dy,
    label: '${bin.pointCount} observations',
    metadata: {
      'binPointCount': bin.pointCount,
      'binXMinimum': bin.dataXRange.minimum,
      'binXMaximum': bin.dataXRange.maximum,
      'binYMinimum': bin.dataYRange.minimum,
      'binYMaximum': bin.dataYRange.maximum,
      'binAggregateValue': bin.aggregateValue,
      'binAggregateSampleCount': bin.aggregateSampleCount,
    },
  );

  static ({double value, int sampleCount})? _aggregate(
    List<ScatterPointGeometry> members,
    ScatterBinConfig config, {
    required int totalPointCount,
  }) {
    if (config.aggregate == ScatterBinAggregate.count) {
      return (value: members.length.toDouble(), sampleCount: members.length);
    }
    if (config.aggregate == ScatterBinAggregate.proportion) {
      return (
        value: members.length / totalPointCount,
        sampleCount: members.length,
      );
    }
    final values = <double>[];
    for (final member in members) {
      final value = _valueFor(member.point, config.valueSource);
      if (value != null && value.isFinite) values.add(value);
    }
    if (values.isEmpty) return null;
    return switch (config.aggregate) {
      ScatterBinAggregate.sum => (
        value: values.fold(0.0, (sum, value) => sum + value),
        sampleCount: values.length,
      ),
      ScatterBinAggregate.mean => (
        value: values.fold(0.0, (sum, value) => sum + value) / values.length,
        sampleCount: values.length,
      ),
      ScatterBinAggregate.minimum => (
        value: values.reduce(math.min),
        sampleCount: values.length,
      ),
      ScatterBinAggregate.maximum => (
        value: values.reduce(math.max),
        sampleCount: values.length,
      ),
      ScatterBinAggregate.count || ScatterBinAggregate.proportion =>
        throw StateError('Count aggregates are resolved before value lookup.'),
    };
  }

  static double? _valueFor(
    ChartDataPoint point,
    ScatterBinValueSource source,
  ) => switch (source) {
    ScatterBinValueSource.x => point.x,
    ScatterBinValueSource.y => point.y,
    ScatterBinValueSource.magnitude => point.magnitude,
    ScatterBinValueSource.colorValue => point.colorValue,
    ScatterBinValueSource.opacityValue => point.opacityValue,
  };

  static double _normalizedIntensity(
    double value, {
    required double minimum,
    required double maximum,
    required bool useSquareRoot,
  }) {
    if (minimum == maximum) return 1;
    final normalized = ((value - minimum) / (maximum - minimum))
        .clamp(0, 1)
        .toDouble();
    return useSquareRoot ? math.sqrt(normalized) : normalized;
  }

  static Path _rectangularPath(Offset center, double size, double gap) {
    final extent = math.max(0.5, (size - gap) / 2);
    return Path()..addRect(
      Rect.fromLTRB(
        center.dx - extent,
        center.dy - extent,
        center.dx + extent,
        center.dy + extent,
      ),
    );
  }

  static (int, int) _hexKey(Offset point, double radius) {
    final q = (2 / 3 * point.dx) / radius;
    final r = (-1 / 3 * point.dx + math.sqrt(3) / 3 * point.dy) / radius;
    return _roundAxial(q, r);
  }

  static (int, int) _roundAxial(double q, double r) {
    var cubeX = q.round();
    var cubeZ = r.round();
    var cubeY = (-q - r).round();
    final xDifference = (cubeX - q).abs();
    final yDifference = (cubeY + q + r).abs();
    final zDifference = (cubeZ - r).abs();
    if (xDifference > yDifference && xDifference > zDifference) {
      cubeX = -cubeY - cubeZ;
    } else if (yDifference > zDifference) {
      cubeY = -cubeX - cubeZ;
    } else {
      cubeZ = -cubeX - cubeY;
    }
    return (cubeX, cubeZ);
  }

  static Offset _hexCenter((int, int) key, double radius) => Offset(
    radius * 1.5 * key.$1,
    radius * math.sqrt(3) * (key.$2 + key.$1 / 2),
  );

  static Path _hexPath(Offset center, double radius, double gap) {
    final effectiveRadius = math.max(0.5, radius - gap / 2);
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = math.pi / 3 * index;
      final point = Offset(
        center.dx + effectiveRadius * math.cos(angle),
        center.dy + effectiveRadius * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }
}

class _ScatterBinCandidate {
  const _ScatterBinCandidate({
    required this.sourcePointIndices,
    required this.center,
    required this.path,
    required this.dataCentroid,
    required this.dataXRange,
    required this.dataYRange,
    required this.aggregateValue,
    required this.aggregateSampleCount,
  });

  final List<int> sourcePointIndices;
  final Offset center;
  final Path path;
  final Offset dataCentroid;
  final ({double minimum, double maximum}) dataXRange;
  final ({double minimum, double maximum}) dataYRange;
  final double aggregateValue;
  final int aggregateSampleCount;
}
