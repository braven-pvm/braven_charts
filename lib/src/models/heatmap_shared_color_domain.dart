// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:collection';

import 'heatmap_chart_series.dart';
import 'heatmap_color_scale.dart';

/// One portable continuous colour domain shared by independent Heatmaps.
///
/// The domain is a host/data composition contract. Applying it does not merge
/// series, introduce another renderer, or make a legend responsible for colour
/// semantics. Missing cells are excluded while every finite measured value,
/// including an application-defined zero, remains part of the domain.
final class HeatmapSharedColorDomain {
  HeatmapSharedColorDomain({
    required this.minimumValue,
    required this.maximumValue,
    List<String> sourceSeriesIds = const [],
  }) : sourceSeriesIds = UnmodifiableListView<String>(
         List<String>.of(sourceSeriesIds),
       ) {
    _validateDomain(minimumValue, maximumValue);
  }

  /// Derives one deterministic domain from the finite values in [series].
  ///
  /// [paddingFraction] expands both ends by this fraction of the observed
  /// span. A constant-valued input receives a small deterministic span so the
  /// resulting domain remains valid for interpolation.
  factory HeatmapSharedColorDomain.fromSeries(
    Iterable<HeatmapChartSeries> series, {
    double paddingFraction = 0,
  }) {
    if (!paddingFraction.isFinite || paddingFraction < 0) {
      throw ArgumentError.value(
        paddingFraction,
        'paddingFraction',
        'must be finite and greater than or equal to zero',
      );
    }

    double? minimum;
    double? maximum;
    final sourceIds = <String>[];
    final seenSourceIds = <String>{};
    for (final heatmap in series) {
      if (seenSourceIds.add(heatmap.id)) sourceIds.add(heatmap.id);
      for (final value in heatmap.measuredValues) {
        if (!value.isFinite) continue;
        minimum = minimum == null || value < minimum ? value : minimum;
        maximum = maximum == null || value > maximum ? value : maximum;
      }
    }
    if (minimum == null || maximum == null) {
      throw ArgumentError.value(
        series,
        'series',
        'must contain at least one finite measured Heatmap value',
      );
    }

    if (maximum == minimum) {
      final halfSpan = (minimum.abs() * 0.000001).clamp(
        0.000001,
        double.infinity,
      );
      minimum -= halfSpan;
      maximum += halfSpan;
    }
    final padding = (maximum - minimum) * paddingFraction;
    return HeatmapSharedColorDomain(
      minimumValue: minimum - padding,
      maximumValue: maximum + padding,
      sourceSeriesIds: sourceIds,
    );
  }

  factory HeatmapSharedColorDomain.fromJson(Map<String, dynamic> json) {
    final minimum = json['minimumValue'];
    final maximum = json['maximumValue'];
    final sourceIds = json['sourceSeriesIds'];
    if (minimum is! num || maximum is! num) {
      throw const FormatException(
        'Heatmap shared colour domains require numeric minimumValue and '
        'maximumValue',
      );
    }
    if (sourceIds != null && sourceIds is! List) {
      throw const FormatException('sourceSeriesIds must be a JSON list');
    }
    return HeatmapSharedColorDomain(
      minimumValue: minimum.toDouble(),
      maximumValue: maximum.toDouble(),
      sourceSeriesIds: sourceIds == null
          ? const []
          : [
              for (final id in sourceIds)
                if (id is String)
                  id
                else
                  throw const FormatException(
                    'sourceSeriesIds entries must be strings',
                  ),
            ],
    );
  }

  final double minimumValue;
  final double maximumValue;

  /// Stable source-series provenance in first-seen order.
  final List<String> sourceSeriesIds;

  double get span => maximumValue - minimumValue;

  /// Applies this domain to a sequential or diverging [scale].
  ///
  /// A diverging scale's semantic midpoint must already lie within this
  /// domain. Threshold scales are rejected because their ordered bands, not a
  /// continuous minimum/maximum pair, own their colour semantics.
  HeatmapColorScale scaleFor(HeatmapColorScale scale, {bool? showLegend}) =>
      scale.withDomain(
        minimumValue: minimumValue,
        maximumValue: maximumValue,
        showLegend: showLegend,
      );

  Map<String, dynamic> toJson() => {
    'minimumValue': minimumValue,
    'maximumValue': maximumValue,
    'sourceSeriesIds': sourceSeriesIds,
  };

  static void _validateDomain(double minimum, double maximum) {
    if (!minimum.isFinite) {
      throw ArgumentError.value(minimum, 'minimumValue', 'must be finite');
    }
    if (!maximum.isFinite || maximum <= minimum) {
      throw ArgumentError.value(
        maximum,
        'maximumValue',
        'must be finite and greater than minimumValue ($minimum)',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapSharedColorDomain &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          _listsEqual(other.sourceSeriesIds, sourceSeriesIds);

  @override
  int get hashCode =>
      Object.hash(minimumValue, maximumValue, Object.hashAll(sourceSeriesIds));
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
