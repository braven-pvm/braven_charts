import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../layout/radial_pane_geometry.dart';

const double _tau = math.pi * 2;

/// Maps authored Radar categories to exact spoke angles.
@immutable
class RadarCategoryScale {
  factory RadarCategoryScale({
    required RadialPaneGeometry pane,
    required List<String> categories,
  }) {
    if ((pane.sweepAngle - _tau).abs() > 1e-9) {
      throw ArgumentError.value(
        pane.sweepAngle,
        'pane.sweepAngle',
        'Radar V1 requires a full-circle pane',
      );
    }
    if (pane.innerRadius != 0) {
      throw ArgumentError.value(
        pane.innerRadius,
        'pane.innerRadius',
        'Radar V1 requires a zero inner radius',
      );
    }
    if (categories.length < 3) {
      throw ArgumentError.value(
        categories.length,
        'categories',
        'Radar requires at least three categories',
      );
    }
    final indices = <String, int>{};
    for (final (index, category) in categories.indexed) {
      final identity = category.trim();
      if (identity.isEmpty || indices.containsKey(identity)) {
        throw ArgumentError.value(
          category,
          'categories[$index]',
          'Radar category identities must be visible and unique',
        );
      }
      indices[identity] = index;
    }
    return RadarCategoryScale._(
      pane: pane,
      categories: List.unmodifiable(categories.map((value) => value.trim())),
      categoryIndices: Map.unmodifiable(indices),
    );
  }

  const RadarCategoryScale._({
    required this.pane,
    required this.categories,
    required Map<String, int> categoryIndices,
  }) : _categoryIndices = categoryIndices;

  final RadialPaneGeometry pane;
  final List<String> categories;
  final Map<String, int> _categoryIndices;

  double get stepAngle => pane.sweepAngle / categories.length;

  double angleAt(int index) {
    RangeError.checkValidIndex(index, categories, 'index');
    final direction = pane.clockwise ? 1.0 : -1.0;
    return pane.startAngle + direction * stepAngle * index;
  }

  double? angleForCategory(String category) {
    final index = _categoryIndices[category.trim()];
    return index == null ? null : angleAt(index);
  }
}
