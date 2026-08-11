import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../axis/polar_numeric_scale.dart';
import '../axis/radar_category_scale.dart';
import '../coordinates/polar_transform.dart';

/// One explicit closed edge between two Radar vertices.
@immutable
class RadarProfileEdge {
  const RadarProfileEdge({
    required this.startIndex,
    required this.endIndex,
    required this.start,
    required this.end,
  });

  final int startIndex;
  final int endIndex;
  final Offset start;
  final Offset end;
}

/// Pure geometry for one Radar profile.
@immutable
class RadarProfileGeometry {
  RadarProfileGeometry({
    required List<Offset> vertices,
    required List<RadarProfileEdge> closedEdges,
  }) : vertices = UnmodifiableListView(vertices),
       closedEdges = UnmodifiableListView(closedEdges);

  /// Exactly one vertex per source category; the first is never duplicated.
  final List<Offset> vertices;

  /// Includes the final edge from the last source vertex back to the first.
  final List<RadarProfileEdge> closedEdges;
}

/// Pure geometry for one radial grid ring.
@immutable
class RadarGridRingGeometry {
  RadarGridRingGeometry({
    required this.fraction,
    required this.radius,
    required List<Offset> polygonVertices,
  }) : polygonVertices = UnmodifiableListView(polygonVertices);

  final double fraction;
  final double radius;
  final List<Offset> polygonVertices;
}

/// Deterministic category/profile geometry shared by Radar renderers.
@immutable
class RadarChartGeometry {
  RadarChartGeometry({
    required this.categoryScale,
    required this.numericScale,
  }) {
    if (!identical(categoryScale.pane, numericScale.pane)) {
      throw ArgumentError(
        'Radar category and numeric scales must share one pane',
      );
    }
    if (numericScale.mode != PolarNumericScaleMode.linear ||
        numericScale.minimum < 0) {
      throw ArgumentError(
        'Radar V1 requires one non-negative linear radial scale',
      );
    }
  }

  final RadarCategoryScale categoryScale;
  final PolarNumericScale numericScale;

  PolarTransform get _transform => PolarTransform(categoryScale.pane);

  RadarProfileGeometry profileFor(List<double> values) {
    if (values.length != categoryScale.categories.length) {
      throw ArgumentError.value(
        values.length,
        'values',
        'Radar value count must match the shared category count',
      );
    }
    final vertices = <Offset>[];
    for (final (index, value) in values.indexed) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(
          value,
          'values[$index]',
          'Radar values must be finite and non-negative',
        );
      }
      vertices.add(
        _transform.toPlot(
          angle: categoryScale.angleAt(index),
          radius: numericScale.valueToRadius(value),
        ),
      );
    }
    return RadarProfileGeometry(
      vertices: vertices,
      closedEdges: [
        for (var index = 0; index < vertices.length; index++)
          RadarProfileEdge(
            startIndex: index,
            endIndex: (index + 1) % vertices.length,
            start: vertices[index],
            end: vertices[(index + 1) % vertices.length],
          ),
      ],
    );
  }

  RadarGridRingGeometry ringAt(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(
        fraction,
        'fraction',
        'Grid fraction must be finite and in [0, 1]',
      );
    }
    final radius =
        categoryScale.pane.innerRadius +
        fraction *
            (categoryScale.pane.outerRadius - categoryScale.pane.innerRadius);
    return RadarGridRingGeometry(
      fraction: fraction,
      radius: radius,
      polygonVertices: [
        for (var index = 0; index < categoryScale.categories.length; index++)
          _transform.toPlot(
            angle: categoryScale.angleAt(index),
            radius: radius,
          ),
      ],
    );
  }
}
