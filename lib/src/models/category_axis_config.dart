// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../meta/chart_surface.dart';

/// Controls how categorical axis labels are reduced when space is constrained.
enum CategoryLabelDensity {
  /// Preserve readable spacing by showing a representative subset of labels.
  auto,

  /// Paint every visible category label, even when labels may overlap.
  showAll,
}

/// Controls how a category label uses its available paint extent.
enum CategoryLabelOverflow {
  /// Wrap onto at most [CategoryAxisConfig.maxLabelLines] lines.
  wrap,

  /// Keep one line and replace clipped text with an ellipsis.
  ellipsis,
}

/// First-class category metadata for a Cartesian axis.
///
/// Category identity remains stable and serializable while chart geometry keeps
/// using numeric coordinates. Category at index `i` maps to data value `i`.
/// This lets existing zoom, pan, selection, annotations, and table linking keep
/// one coordinate contract without requiring hosts to write label formatters.
@chartSurface
class CategoryAxisConfig {
  const CategoryAxisConfig({
    required this.categories,
    this.labelDensity = CategoryLabelDensity.auto,
    this.labelOverflow = CategoryLabelOverflow.wrap,
    this.minimumCategoryExtent = 56,
    this.maximumLabelExtent = 104,
    this.maxLabelLines = 2,
    this.labelRotationDegrees = 0,
    this.autoViewport = true,
  }) : assert(minimumCategoryExtent > 0),
       assert(maximumLabelExtent > 0),
       assert(maxLabelLines > 0),
       assert(labelRotationDegrees >= -90 && labelRotationDegrees <= 90);

  /// Labels in the same stable order as integer axis values.
  final List<String> categories;

  /// Label-density policy used independently for every visible viewport.
  final CategoryLabelDensity labelDensity;

  /// Wrapping or truncation policy for long labels.
  final CategoryLabelOverflow labelOverflow;

  /// Minimum logical pixels reserved for each visible category.
  ///
  /// This drives automatic label thinning and the optional initial viewport.
  final double minimumCategoryExtent;

  /// Maximum width available to one horizontal-axis category label.
  ///
  /// On transposed horizontal bar charts this caps the category-axis width.
  final double maximumLabelExtent;

  /// Maximum wrapped lines for horizontal-axis labels.
  final int maxLabelLines;

  /// Clockwise rotation applied to horizontal-axis labels.
  final double labelRotationDegrees;

  /// Whether the initial viewport should preserve [minimumCategoryExtent].
  ///
  /// When the chart cannot fit every category, the first readable window is
  /// shown. Existing pan, zoom, and scrollbar behavior navigate the full range.
  final bool autoViewport;

  /// Full category-domain minimum, including half a slot before the first item.
  double get domainMin => -0.5;

  /// Full category-domain maximum, including half a slot after the last item.
  double get domainMax => categories.length - 0.5;

  /// Returns the category mapped to [value], or null between category centers.
  String? labelFor(double value) {
    if (!value.isFinite) return null;
    final index = value.round();
    if ((value - index).abs() > 0.000001 ||
        index < 0 ||
        index >= categories.length) {
      return null;
    }
    return categories[index];
  }

  /// Validates category identity and ordering for a live axis.
  ///
  /// An empty list is valid and means the axis remains numeric. Once categories
  /// are present, every label must be non-empty and unique so integer
  /// coordinates resolve to one durable semantic identity.
  void validate({String parameterName = 'categoryAxis'}) {
    final identities = <String>{};
    for (var index = 0; index < categories.length; index++) {
      final category = categories[index];
      if (category.trim().isEmpty) {
        throw ArgumentError.value(
          category,
          '$parameterName.categories[$index]',
          'must not be empty or whitespace',
        );
      }
      if (!identities.add(category)) {
        throw ArgumentError.value(
          category,
          '$parameterName.categories[$index]',
          'duplicates an earlier category',
        );
      }
    }
  }

  CategoryAxisConfig copyWith({
    List<String>? categories,
    CategoryLabelDensity? labelDensity,
    CategoryLabelOverflow? labelOverflow,
    double? minimumCategoryExtent,
    double? maximumLabelExtent,
    int? maxLabelLines,
    double? labelRotationDegrees,
    bool? autoViewport,
  }) => CategoryAxisConfig(
    categories: categories ?? this.categories,
    labelDensity: labelDensity ?? this.labelDensity,
    labelOverflow: labelOverflow ?? this.labelOverflow,
    minimumCategoryExtent: minimumCategoryExtent ?? this.minimumCategoryExtent,
    maximumLabelExtent: maximumLabelExtent ?? this.maximumLabelExtent,
    maxLabelLines: maxLabelLines ?? this.maxLabelLines,
    labelRotationDegrees: labelRotationDegrees ?? this.labelRotationDegrees,
    autoViewport: autoViewport ?? this.autoViewport,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAxisConfig &&
          _listEquals(other.categories, categories) &&
          other.labelDensity == labelDensity &&
          other.labelOverflow == labelOverflow &&
          other.minimumCategoryExtent == minimumCategoryExtent &&
          other.maximumLabelExtent == maximumLabelExtent &&
          other.maxLabelLines == maxLabelLines &&
          other.labelRotationDegrees == labelRotationDegrees &&
          other.autoViewport == autoViewport;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categories),
    labelDensity,
    labelOverflow,
    minimumCategoryExtent,
    maximumLabelExtent,
    maxLabelLines,
    labelRotationDegrees,
    autoViewport,
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
