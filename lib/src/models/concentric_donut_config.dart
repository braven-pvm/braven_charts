import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import 'donut_chart_config.dart';

/// Determines which radial edge receives the first Donut series.
enum ConcentricRingOrder {
  /// The first series is the outermost ring and subsequent series move inward.
  outerToInner,

  /// The first series is the innermost ring and subsequent series move outward.
  innerToOuter,
}

/// Default organization used when a Concentric Donut builds its legend.
enum ConcentricDonutLegendMode {
  /// Place each ring's categories beneath an unambiguous ring heading.
  groupedByRing,

  /// Present one flat sequence whose items retain their ring identity.
  flat,
}

/// Plot-level composition settings for two or more Donut series.
///
/// Each `DonutChartSeries` remains an independent part-to-whole distribution.
/// This configuration only controls how those series occupy one shared radial
/// pane; [ringWeights] affect visual band thickness and never alter data totals.
@immutable
@chartSurface
class ConcentricDonutConfig {
  /// Creates a Concentric Donut composition.
  const ConcentricDonutConfig({
    this.innerRadiusFactor = 0.32,
    this.outerRadiusFactor = 1,
    this.ringGap = 4,
    this.order = ConcentricRingOrder.outerToInner,
    this.ringWeights = const <String, double>{},
    this.legendMode = ConcentricDonutLegendMode.groupedByRing,
    this.centerContent = const DonutCenterContent(),
  });

  /// Inner boundary of the shared pane as a fraction of available radius.
  final double innerRadiusFactor;

  /// Outer boundary of the shared pane as a fraction of available radius.
  final double outerRadiusFactor;

  /// Empty logical pixels inserted between adjacent rings.
  final double ringGap;

  /// Maps source-series order onto the radial direction.
  final ConcentricRingOrder order;

  /// Optional relative band thickness keyed by stable series ID.
  ///
  /// Series without an entry use a weight of `1`.
  final Map<String, double> ringWeights;

  /// Default legend organization for the composition.
  final ConcentricDonutLegendMode legendMode;

  /// Portable fallback rendered in the composition's one shared center.
  final DonutCenterContent centerContent;

  /// Returns a copy with selected fields replaced.
  ConcentricDonutConfig copyWith({
    double? innerRadiusFactor,
    double? outerRadiusFactor,
    double? ringGap,
    ConcentricRingOrder? order,
    Map<String, double>? ringWeights,
    ConcentricDonutLegendMode? legendMode,
    DonutCenterContent? centerContent,
  }) => ConcentricDonutConfig(
    innerRadiusFactor: innerRadiusFactor ?? this.innerRadiusFactor,
    outerRadiusFactor: outerRadiusFactor ?? this.outerRadiusFactor,
    ringGap: ringGap ?? this.ringGap,
    order: order ?? this.order,
    ringWeights: ringWeights ?? this.ringWeights,
    legendMode: legendMode ?? this.legendMode,
    centerContent: centerContent ?? this.centerContent,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConcentricDonutConfig &&
          innerRadiusFactor == other.innerRadiusFactor &&
          outerRadiusFactor == other.outerRadiusFactor &&
          ringGap == other.ringGap &&
          order == other.order &&
          mapEquals(ringWeights, other.ringWeights) &&
          legendMode == other.legendMode &&
          centerContent == other.centerContent;

  @override
  int get hashCode => Object.hash(
    innerRadiusFactor,
    outerRadiusFactor,
    ringGap,
    order,
    Object.hashAllUnordered(
      ringWeights.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    legendMode,
    centerContent,
  );
}
