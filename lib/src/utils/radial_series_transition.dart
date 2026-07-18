// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/chart_data_point.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/radial_category_series.dart';
import '../models/segment_style.dart';

/// Identity-aware data transitions for first-class Pie and Donut series.
abstract final class RadialSeriesTransition {
  /// Whether two series can morph through the canonical radial geometry.
  ///
  /// Category insertion, removal, reordering, grouping, and chart-type changes
  /// use the structural fade path instead.
  static bool canMorph(RadialCategorySeries from, RadialCategorySeries to) {
    if (from.runtimeType != to.runtimeType || from.id != to.id) return false;
    if (from.sliceGroupingConfig != null || to.sliceGroupingConfig != null) {
      return false;
    }
    if ((from.sliceRadiusConfig == null) != (to.sliceRadiusConfig == null)) {
      return false;
    }
    final fromKeys = identityKeys(from.points);
    final toKeys = identityKeys(to.points);
    if (fromKeys.length != toKeys.length) return false;
    for (var index = 0; index < fromKeys.length; index++) {
      if (fromKeys[index] != toKeys[index]) return false;
    }
    return true;
  }

  /// Interpolates data or performs a two-phase structural fade.
  static RadialCategorySeries interpolate({
    required RadialCategorySeries from,
    required RadialCategorySeries to,
    required double progress,
    required double effectiveOpacity,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (t >= 1) return to;
    if (!canMorph(from, to)) {
      if (t < 0.5) {
        return _withStructuralOpacity(from, (1 - t * 2) * effectiveOpacity);
      }
      return _withStructuralOpacity(to, ((t - 0.5) * 2) * effectiveOpacity);
    }

    final points = <ChartDataPoint>[];
    for (var index = 0; index < to.points.length; index++) {
      points.add(_interpolatePoint(from.points[index], to.points[index], t));
    }
    return _copyWithPoints(to, points);
  }

  /// Stable identities used for transition matching and state remapping.
  ///
  /// Unique labels are preferred. Duplicate labels are disambiguated by X,
  /// then by their occurrence so valid duplicate categories remain supported.
  static List<String> identityKeys(List<ChartDataPoint> points) {
    final labelCounts = <String, int>{};
    final pairCounts = <String, int>{};
    for (final point in points) {
      final label = point.label!.trim();
      labelCounts[label] = (labelCounts[label] ?? 0) + 1;
      final pair = '$label\u0000${point.x}';
      pairCounts[pair] = (pairCounts[pair] ?? 0) + 1;
    }
    final occurrences = <String, int>{};
    return <String>[
      for (final point in points)
        () {
          final label = point.label!.trim();
          if (labelCounts[label] == 1) return 'label:$label';
          final pair = '$label\u0000${point.x}';
          if (pairCounts[pair] == 1) return 'pair:$pair';
          final occurrence = occurrences[pair] ?? 0;
          occurrences[pair] = occurrence + 1;
          return 'pair:$pair\u0000$occurrence';
        }(),
    ];
  }

  static ChartDataPoint _interpolatePoint(
    ChartDataPoint from,
    ChartDataPoint to,
    double t,
  ) {
    final fromSize = from.pointStyle?.size;
    final toSize = to.pointStyle?.size;
    final interpolatedSize = fromSize == null || toSize == null
        ? toSize
        : _lerp(fromSize, toSize, t);
    final targetStyle = to.pointStyle;
    final pointStyle = targetStyle == null && interpolatedSize == null
        ? null
        : (targetStyle ?? const PointStyle()).copyWith(
            size: interpolatedSize,
            clearSize: interpolatedSize == null,
          );
    return to.copyWith(
      x: _lerp(from.x, to.x, t),
      y: _lerp(from.y, to.y, t),
      pointStyle: pointStyle,
      clearPointStyle: pointStyle == null,
    );
  }

  static RadialCategorySeries _withStructuralOpacity(
    RadialCategorySeries series,
    double opacity,
  ) {
    final hiddenLabels = series.dataLabels.copyWith(isVisible: false);
    return switch (series) {
      final PieChartSeries pie => pie.copyWith(
        pieStyle: pie.pieStyle.copyWith(
          opacity: opacity.clamp(0.0, 1.0),
          animationMode: PieAnimationMode.none,
        ),
        dataLabels: hiddenLabels,
      ),
      final DonutChartSeries donut => donut.copyWith(
        donutStyle: donut.donutStyle.copyWith(
          opacity: opacity.clamp(0.0, 1.0),
          animationMode: PieAnimationMode.none,
        ),
        dataLabels: hiddenLabels,
      ),
      _ => throw StateError('Unsupported radial series ${series.runtimeType}'),
    };
  }

  static RadialCategorySeries _copyWithPoints(
    RadialCategorySeries series,
    List<ChartDataPoint> points,
  ) => switch (series) {
    final PieChartSeries pie => pie.copyWith(points: points),
    final DonutChartSeries donut => donut.copyWith(points: points),
    _ => throw StateError('Unsupported radial series ${series.runtimeType}'),
  };

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
