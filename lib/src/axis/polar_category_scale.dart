import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../layout/radial_pane_geometry.dart';

const double _tau = math.pi * 2;
const double _epsilon = 1e-9;

/// One immutable category band on an angular polar axis.
@immutable
class PolarCategoryBand {
  /// Creates a resolved band.
  const PolarCategoryBand({
    required this.category,
    required this.index,
    required this.startAngle,
    required this.sweepAngle,
  });

  /// Stable category identity used by the source series.
  final String category;

  /// Stable category position in axis traversal order.
  final int index;

  /// Signed band start in Flutter canvas radians.
  final double startAngle;

  /// Signed band span. Positive is clockwise in canvas coordinates.
  final double sweepAngle;

  /// Signed end angle of this band.
  double get endAngle => startAngle + sweepAngle;

  /// Angle through the center of this band.
  double get centerAngle => startAngle + sweepAngle / 2;
}

/// Maps stable categories to equal angular bands within a radial pane.
///
/// Padding values are fractions of one category step. [innerPadding] reserves
/// space between adjacent bands, while [outerPadding] reserves symmetric space
/// before the first and after the last band.
@immutable
class PolarCategoryScale {
  /// Validates [categories] and resolves their angular bands against [pane].
  factory PolarCategoryScale({
    required RadialPaneGeometry pane,
    required List<String> categories,
    double innerPadding = 0,
    double outerPadding = 0,
  }) {
    if (categories.isEmpty) {
      throw ArgumentError.value(
        categories,
        'categories',
        'At least one category is required',
      );
    }
    final categoryIndices = <String, int>{};
    for (final (index, category) in categories.indexed) {
      if (category.trim().isEmpty) {
        throw ArgumentError.value(
          category,
          'categories[$index]',
          'Category identity cannot be blank',
        );
      }
      if (categoryIndices.containsKey(category)) {
        throw ArgumentError.value(
          category,
          'categories[$index]',
          'Category identities must be unique',
        );
      }
      categoryIndices[category] = index;
    }
    _validatePadding(innerPadding, 'innerPadding', allowOne: false);
    _validatePadding(outerPadding, 'outerPadding', allowOne: true);

    final effectiveInnerPadding = categories.length == 1 ? 0.0 : innerPadding;
    final denominator =
        categories.length - effectiveInnerPadding + outerPadding * 2;
    final stepAngle = pane.sweepAngle / denominator;
    final bandSweepAngle = stepAngle * (1 - effectiveInnerPadding);
    final direction = pane.clockwise ? 1.0 : -1.0;
    final bands = <PolarCategoryBand>[
      for (final (index, category) in categories.indexed)
        PolarCategoryBand(
          category: category,
          index: index,
          startAngle:
              pane.startAngle + direction * stepAngle * (outerPadding + index),
          sweepAngle: direction * bandSweepAngle,
        ),
    ];

    return PolarCategoryScale._(
      pane: pane,
      categories: List<String>.unmodifiable(categories),
      innerPadding: innerPadding,
      effectiveInnerPadding: effectiveInnerPadding,
      outerPadding: outerPadding,
      stepAngle: stepAngle,
      bandSweepAngle: bandSweepAngle,
      bands: bands,
      categoryIndices: Map<String, int>.unmodifiable(categoryIndices),
    );
  }

  PolarCategoryScale._({
    required this.pane,
    required this.categories,
    required this.innerPadding,
    required double effectiveInnerPadding,
    required this.outerPadding,
    required this.stepAngle,
    required this.bandSweepAngle,
    required List<PolarCategoryBand> bands,
    required Map<String, int> categoryIndices,
  }) : _effectiveInnerPadding = effectiveInnerPadding,
       bands = UnmodifiableListView(bands),
       _categoryIndices = categoryIndices;

  /// Pane whose angular range and direction define this scale.
  final RadialPaneGeometry pane;

  /// Categories in stable axis and keyboard traversal order.
  final List<String> categories;

  /// Requested fractional gap between adjacent category bands.
  final double innerPadding;

  /// Fractional space reserved before and after all bands.
  final double outerPadding;

  /// Unsigned angle allocated to each category slot, including its trailing gap.
  final double stepAngle;

  /// Unsigned visible angular span of every category band.
  final double bandSweepAngle;

  /// Resolved bands in stable category order.
  final List<PolarCategoryBand> bands;

  final double _effectiveInnerPadding;
  final Map<String, int> _categoryIndices;

  /// Returns the band at [index].
  PolarCategoryBand bandAt(int index) {
    RangeError.checkValidIndex(index, bands, 'index');
    return bands[index];
  }

  /// Returns the band for [category], or `null` when it is absent.
  PolarCategoryBand? bandForCategory(String category) {
    final index = _categoryIndices[category];
    return index == null ? null : bands[index];
  }

  /// Returns the band index containing [angle], excluding configured padding.
  int? indexForAngle(double angle) {
    if (!angle.isFinite) return null;
    var delta = pane.clockwise
        ? _normalizeAngle(angle - pane.startAngle)
        : _normalizeAngle(pane.startAngle - angle);
    if (delta >= _tau - _epsilon) delta = 0;

    final fullSweep = (pane.sweepAngle - _tau).abs() <= _epsilon;
    if (!fullSweep && delta > pane.sweepAngle + _epsilon) return null;

    var relativeStep = delta / stepAngle - outerPadding;
    if (relativeStep < -_epsilon) return null;
    if (relativeStep < 0) relativeStep = 0;

    var index = relativeStep.floor();
    var withinStep = relativeStep - index;
    if (index == categories.length &&
        outerPadding == 0 &&
        !fullSweep &&
        (delta - pane.sweepAngle).abs() <= _epsilon) {
      index = categories.length - 1;
      withinStep = 1 - _effectiveInnerPadding;
    }
    if (index < 0 || index >= categories.length) return null;
    if (withinStep > 1 - _effectiveInnerPadding + _epsilon) return null;
    return index;
  }

  /// Returns the category whose visible band contains [angle].
  String? categoryForAngle(double angle) {
    final index = indexForAngle(angle);
    return index == null ? null : categories[index];
  }
}

void _validatePadding(double value, String name, {required bool allowOne}) {
  final maximumIsValid = allowOne ? value <= 1 : value < 1;
  if (!value.isFinite || value < 0 || !maximumIsValid) {
    throw ArgumentError.value(
      value,
      name,
      allowOne
          ? 'Value must be finite and in [0, 1]'
          : 'Value must be finite and in [0, 1)',
    );
  }
}

double _normalizeAngle(double angle) {
  final normalized = angle % _tau;
  return normalized < 0 ? normalized + _tau : normalized;
}
