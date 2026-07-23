// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'channel.dart' show FieldAccessor;

/// How axes scale across facet panels.
///
/// | mode    | x shared | y shared |
/// |---------|----------|----------|
/// | [fixed] | yes      | yes      |
/// | [freeX] | no       | yes      |
/// | [freeY] | yes      | no       |
/// | [free]  | no       | no       |
enum FacetScales { fixed, freeX, freeY, free }

/// Which axes a [FacetScales] mode shares across panels, and whether
/// synchronized interaction is meaningful.
extension FacetScalesSharing on FacetScales {
  /// Whether the X axis carries one global range across every panel.
  bool get sharesX =>
      this == FacetScales.fixed || this == FacetScales.freeY;

  /// Whether the Y axis carries one global range across every panel.
  bool get sharesY =>
      this == FacetScales.fixed || this == FacetScales.freeX;

  /// Whether a shared crosshair-x is meaningful — it is only meaningful when
  /// x is shared, so synchronized interaction is active for [FacetScales.fixed]
  /// and [FacetScales.freeY] and OFF otherwise.
  bool get syncsInteraction => sharesX;
}

/// Immutable faceting configuration for a [PlotSpec].
///
/// Set through `BravenChart.facet(...)`; a non-faceted spec has `facet == null`
/// and behaves exactly as today. Like [Mark], this holds an accessor function,
/// so it is a grammar VALUE (value equality, the accessor compared by
/// identity) with NO `copyWith` and NO `@chartSurface` — it never enters the
/// config surface.
class FacetSpec<T> {
  /// Creates a facet configuration.
  const FacetSpec({
    required this.by,
    this.columns,
    this.scales = FacetScales.fixed,
    this.label,
  });

  /// Categorical field: one panel per distinct value, in first-seen order.
  final FieldAccessor<T, Object?> by;

  /// Grid columns. Null lays the grid out at `ceil(sqrt(panelCount))`.
  final int? columns;

  /// How the axes scale across panels.
  final FacetScales scales;

  /// Optional strip-label prefix, e.g. `'Athlete'`.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacetSpec<T> &&
          other.by == by &&
          other.columns == columns &&
          other.scales == scales &&
          other.label == label;

  @override
  int get hashCode => Object.hash(by, columns, scales, label);

  @override
  String toString() =>
      'FacetSpec(columns: $columns, scales: $scales, label: $label)';
}
