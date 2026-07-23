// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'channel.dart' show FieldAccessor;
import 'mark.dart';
import 'plot_spec.dart';

/// Distinct facet values from [rows] via [by], in FIRST-SEEN (data) order.
///
/// A null value is a valid distinct value and appears once, in the position it
/// was first seen. Deduplication is by `==` (works for String/enum/num/bool).
List<Object?> distinctFacetValues<T>(
  List<T> rows,
  FieldAccessor<T, Object?> by,
) {
  final seen = <Object?>{};
  final ordered = <Object?>[];
  for (final row in rows) {
    final value = by(row);
    if (seen.add(value)) ordered.add(value);
  }
  return ordered;
}

/// Which Cartesian axis a [globalRange] spans.
enum FacetAxis { x, y }

/// A finite `[min, max]` extent computed across the full dataset.
class FacetRange {
  /// Creates a range.
  const FacetRange(this.min, this.max);

  /// Lower bound.
  final double min;

  /// Upper bound.
  final double max;

  @override
  String toString() => 'FacetRange($min, $max)';
}

/// The global min/max of [spec]'s geometry marks along [axis] over [rows].
///
/// Reuses the marks' own position accessors: the [FacetAxis.x] range is the
/// extent of every geometry's `x`; the [FacetAxis.y] range is the extent of
/// every geometry's `y` (a candlestick contributes `open`/`high`/`low`/`close`,
/// so the shared price axis spans the wicks). Reference/derived marks
/// (threshold, band, point, trend) and radial marks contribute nothing.
/// Non-finite accessor
/// output is skipped, exactly as the point families carry it through. Returns
/// null when nothing finite was found.
FacetRange? globalRange<T>(PlotSpec<T> spec, List<T> rows, FacetAxis axis) {
  double? lo;
  double? hi;
  for (final mark in spec.marks) {
    for (final accessor in _axisAccessors(mark, axis)) {
      for (final row in rows) {
        final value = accessor(row).toDouble();
        if (!value.isFinite) continue;
        if (lo == null || value < lo) lo = value;
        if (hi == null || value > hi) hi = value;
      }
    }
  }
  if (lo == null || hi == null) return null;
  return FacetRange(lo, hi);
}

/// The position accessors of [mark] that contribute to [axis].
List<FieldAccessor<T, num>> _axisAccessors<T>(Mark<T> mark, FacetAxis axis) =>
    switch (mark) {
      LineMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      AreaMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      BarMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      ScatterMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      CandlestickMark<T>(
        :final x,
        :final open,
        :final high,
        :final low,
        :final close,
      ) =>
        axis == FacetAxis.x
            ? <FieldAccessor<T, num>>[x]
            : <FieldAccessor<T, num>>[open, high, low, close],
      TrendMark<T>() ||
      ThresholdMark<T>() ||
      BandMark<T>() ||
      PointMark<T>() ||
      // Radial geoms have no Cartesian position, so they contribute nothing to
      // a shared Cartesian facet range. In practice a faceted radial spec is
      // rejected up front (facetedRadialUnsupported); this keeps the switch
      // exhaustive and defensive regardless.
      RadialMark<T>() => const <Never>[],
    };

/// The auto grid width for [panelCount] panels: `ceil(sqrt(n))`, min 1.
int autoColumns(int panelCount) =>
    panelCount <= 1 ? 1 : math.sqrt(panelCount).ceil();
