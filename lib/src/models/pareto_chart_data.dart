// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'chart_data_point.dart';

/// One named input category for a Pareto composition.
@immutable
class ParetoCategory {
  const ParetoCategory({required this.label, required this.value});

  final String label;
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParetoCategory && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'ParetoCategory(label: $label, value: $value)';
}

/// Prepared, immutable data for a Pareto bar-and-line composition.
///
/// Categories are sorted from largest to smallest while equal values preserve
/// their source order. [valuePoints] and [cumulativePoints] deliberately share
/// the same X values and labels so they can be rendered as a bar series and a
/// line series on independent Y axes.
@immutable
class ParetoChartData {
  factory ParetoChartData({required Iterable<ParetoCategory> categories}) {
    final source = categories.toList(growable: false);
    final seenLabels = <String>{};

    for (final category in source) {
      if (category.label.trim().isEmpty) {
        throw ArgumentError.value(
          category.label,
          'categories',
          'Category labels must not be empty',
        );
      }
      if (!seenLabels.add(category.label)) {
        throw ArgumentError.value(
          category.label,
          'categories',
          'Category labels must be unique',
        );
      }
      if (!category.value.isFinite || category.value < 0) {
        throw ArgumentError.value(
          category.value,
          'categories',
          'Category values must be finite and non-negative',
        );
      }
    }

    final indexed =
        <({int index, ParetoCategory category})>[
          for (var index = 0; index < source.length; index++)
            (index: index, category: source[index]),
        ]..sort((a, b) {
          final byValue = b.category.value.compareTo(a.category.value);
          return byValue != 0 ? byValue : a.index.compareTo(b.index);
        });
    final sorted = [for (final item in indexed) item.category];
    final total = sorted.fold<double>(0, (sum, item) => sum + item.value);

    if (sorted.isNotEmpty && total == 0) {
      throw ArgumentError.value(
        source,
        'categories',
        'At least one category value must be greater than zero',
      );
    }

    var runningTotal = 0.0;
    final cumulativePercentages = <double>[];
    for (var index = 0; index < sorted.length; index++) {
      runningTotal += sorted[index].value;
      cumulativePercentages.add(
        index == sorted.length - 1 ? 100.0 : runningTotal / total * 100,
      );
    }

    return ParetoChartData._(
      categories: List.unmodifiable(sorted),
      cumulativePercentages: List.unmodifiable(cumulativePercentages),
      total: total,
    );
  }

  const ParetoChartData._({
    required this.categories,
    required this.cumulativePercentages,
    required this.total,
  });

  /// Categories in descending value order.
  final List<ParetoCategory> categories;

  /// Running contribution to [total], expressed from 0 to 100.
  final List<double> cumulativePercentages;

  /// Sum of all category values.
  final double total;

  List<ChartDataPoint> get valuePoints => List.unmodifiable([
    for (var index = 0; index < categories.length; index++)
      ChartDataPoint(
        x: index.toDouble(),
        y: categories[index].value,
        label: categories[index].label,
      ),
  ]);

  List<ChartDataPoint> get cumulativePoints => List.unmodifiable([
    for (var index = 0; index < categories.length; index++)
      ChartDataPoint(
        x: index.toDouble(),
        y: cumulativePercentages[index],
        label: categories[index].label,
      ),
  ]);

  /// Returns the first sorted category index reaching [percentage].
  int? firstIndexAtOrAbove(double percentage) {
    if (!percentage.isFinite || percentage < 0 || percentage > 100) {
      throw ArgumentError.value(
        percentage,
        'percentage',
        'Percentage must be finite and between 0 and 100',
      );
    }
    for (var index = 0; index < cumulativePercentages.length; index++) {
      if (cumulativePercentages[index] >= percentage) return index;
    }
    return null;
  }
}
