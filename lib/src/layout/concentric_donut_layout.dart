import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/concentric_donut_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';

/// One allocated radial band in a Concentric Donut composition.
@immutable
class ConcentricDonutRingLayout {
  /// Creates an immutable ring allocation.
  const ConcentricDonutRingLayout({
    required this.seriesId,
    required this.ringIndex,
    required this.innerRadius,
    required this.outerRadius,
    required this.weight,
  });

  /// Stable ID of the Donut series rendered in this band.
  final String seriesId;

  /// Source-series index and stable traversal position.
  final int ringIndex;

  /// Inner edge in logical pixels from the shared plot center.
  final double innerRadius;

  /// Outer edge in logical pixels from the shared plot center.
  final double outerRadius;

  /// Relative thickness weight resolved for this series.
  final double weight;

  /// Allocated radial thickness in logical pixels.
  double get thickness => outerRadius - innerRadius;
}

/// Complete non-overlapping radial allocation for a Concentric Donut pane.
@immutable
class ConcentricDonutLayout {
  ConcentricDonutLayout({
    required this.innerRadius,
    required this.outerRadius,
    required this.effectiveRingGap,
    required List<ConcentricDonutRingLayout> rings,
  }) : rings = UnmodifiableListView(rings);

  /// Inner boundary shared by the composition.
  final double innerRadius;

  /// Outer boundary shared by the composition.
  final double outerRadius;

  /// Gap used by this resolved layout.
  ///
  /// This equals [ConcentricDonutConfig.ringGap] for strict and normally sized
  /// layouts. A responsive render may reduce it to retain positive ring bands
  /// when the configured gap no longer fits the available radius.
  final double effectiveRingGap;

  /// Ring bands in source-series and focus-traversal order.
  final List<ConcentricDonutRingLayout> rings;

  /// Returns the allocation for [seriesId], or `null` when it is not present.
  ConcentricDonutRingLayout? ringForSeries(String seriesId) {
    for (final ring in rings) {
      if (ring.seriesId == seriesId) return ring;
    }
    return null;
  }
}

/// Pure allocator for Concentric Donut ring bands.
class ConcentricDonutLayoutCalculator {
  const ConcentricDonutLayoutCalculator._();

  /// Validates the half of [config] that is decidable WITHOUT the ring series:
  /// the pane radii, the ring gap, every ring weight's magnitude and the shared
  /// center's label / custom value.
  ///
  /// Exposed so callers upstream of layout — grammar lowering, artifact
  /// hydration — can reject an unrenderable composition in their own vocabulary
  /// instead of letting it surface as a raw `ArgumentError` at widget mount.
  /// Reusing the calculator's own rules is what stops the two from disagreeing.
  static void validateConfig(ConcentricDonutConfig config) =>
      _validateConfig(config);

  /// Validates [series] against [config]: unique ring ids, ring-weight keys
  /// that name a real ring, and one shared sweep and direction across rings.
  ///
  /// The companion to [validateConfig] for the data-DEPENDENT half. Meaningful
  /// only for a composition the render pipeline actually lays out — that is,
  /// two or more rings.
  static void validateSeries(
    List<DonutChartSeries> series,
    ConcentricDonutConfig config,
  ) => _validateSeries(series, config);

  /// Validates [series] and [config], then allocates their radial bands.
  static ConcentricDonutLayout calculate({
    required List<DonutChartSeries> series,
    required ConcentricDonutConfig config,
    required double availableRadius,
    bool fitRingGap = false,
  }) {
    if (series.length < 2) {
      throw ArgumentError.value(
        series.length,
        'series',
        'A Concentric Donut requires at least two Donut series',
      );
    }
    if (!availableRadius.isFinite || availableRadius <= 0) {
      throw ArgumentError.value(
        availableRadius,
        'availableRadius',
        'Available radius must be finite and greater than zero',
      );
    }
    _validateConfig(config);
    _validateSeries(series, config);

    final innerRadius = availableRadius * config.innerRadiusFactor;
    final outerRadius = availableRadius * config.outerRadiusFactor;
    final radialSpan = outerRadius - innerRadius;
    final effectiveRingGap = fitRingGap
        ? _fittedRingGap(
            requestedGap: config.ringGap,
            radialSpan: radialSpan,
            ringCount: series.length,
          )
        : config.ringGap;
    final totalGap = effectiveRingGap * (series.length - 1);
    final usableThickness = outerRadius - innerRadius - totalGap;
    if (!usableThickness.isFinite || usableThickness <= 0) {
      throw ArgumentError.value(
        usableThickness,
        'config',
        'The pane and ring gaps must leave positive thickness for every ring',
      );
    }

    final weights = [
      for (final ring in series) config.ringWeights[ring.id] ?? 1,
    ];
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    final rings = <ConcentricDonutRingLayout>[];

    switch (config.order) {
      case ConcentricRingOrder.outerToInner:
        var cursor = outerRadius;
        for (var index = 0; index < series.length; index++) {
          final thickness = usableThickness * weights[index] / totalWeight;
          final ringInner = index == series.length - 1
              ? innerRadius
              : cursor - thickness;
          rings.add(
            ConcentricDonutRingLayout(
              seriesId: series[index].id,
              ringIndex: index,
              innerRadius: ringInner,
              outerRadius: cursor,
              weight: weights[index],
            ),
          );
          cursor = ringInner - effectiveRingGap;
        }
      case ConcentricRingOrder.innerToOuter:
        var cursor = innerRadius;
        for (var index = 0; index < series.length; index++) {
          final thickness = usableThickness * weights[index] / totalWeight;
          final ringOuter = index == series.length - 1
              ? outerRadius
              : cursor + thickness;
          rings.add(
            ConcentricDonutRingLayout(
              seriesId: series[index].id,
              ringIndex: index,
              innerRadius: cursor,
              outerRadius: ringOuter,
              weight: weights[index],
            ),
          );
          cursor = ringOuter + effectiveRingGap;
        }
    }

    if (rings.any((ring) => !ring.thickness.isFinite || ring.thickness <= 0)) {
      throw ArgumentError.value(
        rings.map((ring) => ring.thickness).toList(),
        'config',
        'The pane and ring weights must leave positive thickness for every ring',
      );
    }
    return ConcentricDonutLayout(
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      effectiveRingGap: effectiveRingGap,
      rings: rings,
    );
  }

  static double _fittedRingGap({
    required double requestedGap,
    required double radialSpan,
    required int ringCount,
  }) {
    if (ringCount <= 1 || requestedGap == 0) return 0;

    // Preserve at least one logical pixel per ring when the pane permits it.
    // Below that threshold, retain half of the radial span for the rings so a
    // severely constrained chart still degrades to visible, positive bands.
    final minimumTotalRingThickness = math.min(
      radialSpan,
      math.max(radialSpan * 0.5, ringCount.toDouble()),
    );
    final maximumGap = math.max(
      0.0,
      (radialSpan - minimumTotalRingThickness) / (ringCount - 1),
    );
    return math.min(requestedGap, maximumGap);
  }

  static void _validateConfig(ConcentricDonutConfig config) {
    final inner = config.innerRadiusFactor;
    final outer = config.outerRadiusFactor;
    if (!inner.isFinite || inner < 0 || inner >= 1) {
      throw ArgumentError.value(
        inner,
        'config.innerRadiusFactor',
        'Inner radius factor must be finite and in [0, 1)',
      );
    }
    if (!outer.isFinite || outer <= 0 || outer > 1) {
      throw ArgumentError.value(
        outer,
        'config.outerRadiusFactor',
        'Outer radius factor must be finite and in (0, 1]',
      );
    }
    if (inner >= outer) {
      throw ArgumentError.value(
        '$inner >= $outer',
        'config',
        'Inner radius factor must be smaller than outer radius factor',
      );
    }
    if (!config.ringGap.isFinite || config.ringGap < 0) {
      throw ArgumentError.value(
        config.ringGap,
        'config.ringGap',
        'Ring gap must be finite and non-negative',
      );
    }
    for (final entry in config.ringWeights.entries) {
      if (!entry.value.isFinite || entry.value <= 0) {
        throw ArgumentError.value(
          entry.value,
          'config.ringWeights[${entry.key}]',
          'Ring weights must be finite and greater than zero',
        );
      }
    }
    final label = config.centerContent.label?.trim();
    if (config.centerContent.label != null &&
        (label == null || label.isEmpty)) {
      throw ArgumentError.value(
        config.centerContent.label,
        'config.centerContent.label',
        'Center label cannot be blank',
      );
    }
    final customValue = config.centerContent.customValue?.trim();
    if (config.centerContent.valueMode == DonutCenterValueMode.custom &&
        (customValue == null || customValue.isEmpty)) {
      throw ArgumentError.value(
        config.centerContent.customValue,
        'config.centerContent.customValue',
        'Custom center content requires a visible custom value',
      );
    }
  }

  static void _validateSeries(
    List<DonutChartSeries> series,
    ConcentricDonutConfig config,
  ) {
    final ids = <String>{};
    for (final ring in series) {
      if (!ids.add(ring.id)) {
        throw ArgumentError.value(
          ring.id,
          'series',
          'Concentric Donut series IDs must be unique',
        );
      }
    }
    for (final weightedId in config.ringWeights.keys) {
      if (!ids.contains(weightedId)) {
        throw ArgumentError.value(
          weightedId,
          'config.ringWeights',
          'Ring weight key "$weightedId" does not identify a real series',
        );
      }
    }

    final reference = series.first.donutStyle;
    for (final ring in series.skip(1)) {
      if (ring.donutStyle.sweepAngleDegrees != reference.sweepAngleDegrees) {
        throw ArgumentError.value(
          ring.donutStyle.sweepAngleDegrees,
          'series[${ring.id}].donutStyle.sweepAngleDegrees',
          'Every Concentric Donut ring must use the same sweep',
        );
      }
      if (ring.donutStyle.clockwise != reference.clockwise) {
        throw ArgumentError.value(
          ring.donutStyle.clockwise,
          'series[${ring.id}].donutStyle.clockwise',
          'Every Concentric Donut ring must use the same direction',
        );
      }
    }
  }
}
