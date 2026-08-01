// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

/// Native numeric colour-mapping strategy for Heatmap values.
enum HeatmapColorScaleType {
  /// Interpolates from low to high through an ordered colour ramp.
  sequential,

  /// Interpolates on either side of a semantic numeric midpoint.
  diverging,

  /// Resolves one discrete colour band around ordered numeric thresholds.
  threshold,
}

/// Maps an independent Heatmap measured value to a cell colour.
///
/// The scale is independent from legend layout. A chart can therefore resolve
/// identical colours for painting, tooltips, generated source, and a native
/// legend without making the legend the owner of scale semantics.
final class HeatmapColorScale {
  HeatmapColorScale._({
    required this.type,
    required List<Color> colors,
    required List<double> thresholds,
    required List<String> bandLabels,
    required this.minimumValue,
    required this.maximumValue,
    required this.midpoint,
    required this.reverse,
    required this.clamp,
    required this.missingColor,
    required this.label,
    required this.unit,
    required this.showLegend,
  }) : colors = List<Color>.unmodifiable(colors),
       thresholds = List<double>.unmodifiable(thresholds),
       bandLabels = List<String>.unmodifiable(bandLabels);

  factory HeatmapColorScale.sequential({
    required List<Color> colors,
    double? minimumValue,
    double? maximumValue,
    bool reverse = false,
    bool clamp = true,
    Color missingColor = const Color(0x00000000),
    String label = 'Value',
    String? unit,
    bool showLegend = true,
  }) {
    _validateRamp(colors, parameterName: 'colors');
    _validateDomain(minimumValue, maximumValue);
    return HeatmapColorScale._(
      type: HeatmapColorScaleType.sequential,
      colors: colors,
      thresholds: const [],
      bandLabels: const [],
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      midpoint: null,
      reverse: reverse,
      clamp: clamp,
      missingColor: missingColor,
      label: label,
      unit: unit,
      showLegend: showLegend,
    );
  }

  factory HeatmapColorScale.diverging({
    required Color lowColor,
    required Color midpointColor,
    required Color highColor,
    required double midpoint,
    double? minimumValue,
    double? maximumValue,
    bool reverse = false,
    bool clamp = true,
    Color missingColor = const Color(0x00000000),
    String label = 'Value',
    String? unit,
    bool showLegend = true,
  }) {
    _validateDomain(minimumValue, maximumValue);
    if (!midpoint.isFinite) {
      throw ArgumentError.value(midpoint, 'midpoint', 'must be finite');
    }
    if (minimumValue != null && midpoint < minimumValue) {
      throw ArgumentError.value(
        midpoint,
        'midpoint',
        'must be greater than or equal to minimumValue',
      );
    }
    if (maximumValue != null && midpoint > maximumValue) {
      throw ArgumentError.value(
        midpoint,
        'midpoint',
        'must be less than or equal to maximumValue',
      );
    }
    return HeatmapColorScale._(
      type: HeatmapColorScaleType.diverging,
      colors: [lowColor, midpointColor, highColor],
      thresholds: const [],
      bandLabels: const [],
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      midpoint: midpoint,
      reverse: reverse,
      clamp: clamp,
      missingColor: missingColor,
      label: label,
      unit: unit,
      showLegend: showLegend,
    );
  }

  factory HeatmapColorScale.threshold({
    required List<double> thresholds,
    required List<Color> colors,
    List<String> bandLabels = const [],
    Color missingColor = const Color(0x00000000),
    String label = 'Value',
    String? unit,
    bool showLegend = true,
    bool reverse = false,
  }) {
    if (colors.length != thresholds.length + 1 || colors.isEmpty) {
      throw ArgumentError(
        'A threshold Heatmap scale requires exactly one more color than '
        'thresholds',
      );
    }
    for (var index = 0; index < thresholds.length; index++) {
      final threshold = thresholds[index];
      if (!threshold.isFinite) {
        throw ArgumentError.value(
          threshold,
          'thresholds[$index]',
          'must be finite',
        );
      }
      if (index > 0 && threshold <= thresholds[index - 1]) {
        throw ArgumentError.value(
          threshold,
          'thresholds[$index]',
          'must be strictly greater than the previous threshold',
        );
      }
    }
    if (bandLabels.isNotEmpty && bandLabels.length != colors.length) {
      throw ArgumentError(
        'bandLabels must be empty or contain one label per color band',
      );
    }
    return HeatmapColorScale._(
      type: HeatmapColorScaleType.threshold,
      colors: colors,
      thresholds: thresholds,
      bandLabels: bandLabels,
      minimumValue: null,
      maximumValue: null,
      midpoint: null,
      reverse: reverse,
      clamp: true,
      missingColor: missingColor,
      label: label,
      unit: unit,
      showLegend: showLegend,
    );
  }

  final HeatmapColorScaleType type;
  final List<Color> colors;
  final List<double> thresholds;
  final List<String> bandLabels;
  final double? minimumValue;
  final double? maximumValue;
  final double? midpoint;
  final bool reverse;
  final bool clamp;
  final Color missingColor;
  final String label;
  final String? unit;
  final bool showLegend;

  /// Returns this continuous colour scale with an explicit numeric domain.
  ///
  /// This is useful when several independent Heatmaps must remain visually
  /// comparable. Threshold scales already own a fixed set of semantic bands
  /// and therefore do not accept a continuous domain.
  HeatmapColorScale withDomain({
    required double minimumValue,
    required double maximumValue,
    bool? showLegend,
  }) {
    switch (type) {
      case HeatmapColorScaleType.sequential:
        return HeatmapColorScale.sequential(
          colors: colors,
          minimumValue: minimumValue,
          maximumValue: maximumValue,
          reverse: reverse,
          clamp: clamp,
          missingColor: missingColor,
          label: label,
          unit: unit,
          showLegend: showLegend ?? this.showLegend,
        );
      case HeatmapColorScaleType.diverging:
        return HeatmapColorScale.diverging(
          lowColor: colors[0],
          midpointColor: colors[1],
          highColor: colors[2],
          midpoint: midpoint!,
          minimumValue: minimumValue,
          maximumValue: maximumValue,
          reverse: reverse,
          clamp: clamp,
          missingColor: missingColor,
          label: label,
          unit: unit,
          showLegend: showLegend ?? this.showLegend,
        );
      case HeatmapColorScaleType.threshold:
        throw UnsupportedError(
          'Threshold Heatmap scales use fixed semantic bands and cannot '
          'accept a continuous domain',
        );
    }
  }

  /// Resolves one measured value against the fixed or caller-resolved domain.
  ///
  /// A null or explicitly missing value uses [missingColor]. A finite measured
  /// value outside an unclamped sequential/diverging domain returns null.
  Color? colorFor(
    double? value, {
    required double resolvedMinimumValue,
    required double resolvedMaximumValue,
    bool isMissing = false,
  }) {
    if (isMissing || value == null) return missingColor;
    if (!value.isFinite) return null;
    if (type == HeatmapColorScaleType.threshold) {
      final index = _thresholdBandIndex(value);
      return reverse ? colors[colors.length - 1 - index] : colors[index];
    }

    final minimum = minimumValue ?? resolvedMinimumValue;
    final maximum = maximumValue ?? resolvedMaximumValue;
    if (!minimum.isFinite || !maximum.isFinite || maximum < minimum) {
      return null;
    }
    if (!clamp && (value < minimum || value > maximum)) return null;
    final bounded = value.clamp(minimum, maximum).toDouble();

    if (type == HeatmapColorScaleType.diverging) {
      final semanticMidpoint = midpoint!;
      if (semanticMidpoint < minimum || semanticMidpoint > maximum) {
        return null;
      }
      final lowColor = reverse ? colors[2] : colors[0];
      final highColor = reverse ? colors[0] : colors[2];
      if (bounded <= semanticMidpoint) {
        final progress = semanticMidpoint <= minimum
            ? 1.0
            : (bounded - minimum) / (semanticMidpoint - minimum);
        return Color.lerp(lowColor, colors[1], progress);
      }
      final progress = maximum <= semanticMidpoint
          ? 0.0
          : (bounded - semanticMidpoint) / (maximum - semanticMidpoint);
      return Color.lerp(colors[1], highColor, progress);
    }

    var progress = maximum <= minimum
        ? 0.5
        : (bounded - minimum) / (maximum - minimum);
    if (reverse) progress = 1 - progress;
    final scaled = progress * (colors.length - 1);
    final lower = scaled.floor().clamp(0, colors.length - 1);
    final upper = scaled.ceil().clamp(0, colors.length - 1);
    if (lower == upper) return colors[lower];
    return Color.lerp(colors[lower], colors[upper], scaled - lower);
  }

  String? bandLabelFor(double? value) {
    if (type != HeatmapColorScaleType.threshold ||
        value == null ||
        !value.isFinite ||
        bandLabels.isEmpty) {
      return null;
    }
    final index = _thresholdBandIndex(value);
    return bandLabels[index];
  }

  int _thresholdBandIndex(double value) {
    var lower = 0;
    var upper = thresholds.length;
    while (lower < upper) {
      final middle = lower + ((upper - lower) >> 1);
      if (value < thresholds[middle]) {
        upper = middle;
      } else {
        lower = middle + 1;
      }
    }
    return lower;
  }

  static void _validateRamp(
    List<Color> colors, {
    required String parameterName,
  }) {
    if (colors.length < 2) {
      throw ArgumentError.value(
        colors,
        parameterName,
        'must contain at least two colors',
      );
    }
  }

  static void _validateDomain(double? minimum, double? maximum) {
    if (minimum != null && !minimum.isFinite) {
      throw ArgumentError.value(minimum, 'minimumValue', 'must be finite');
    }
    if (maximum != null && !maximum.isFinite) {
      throw ArgumentError.value(maximum, 'maximumValue', 'must be finite');
    }
    if (minimum != null && maximum != null && maximum <= minimum) {
      throw ArgumentError.value(
        maximum,
        'maximumValue',
        'must be greater than minimumValue ($minimum)',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapColorScale &&
          other.type == type &&
          _listsEqual(other.colors, colors) &&
          _listsEqual(other.thresholds, thresholds) &&
          _listsEqual(other.bandLabels, bandLabels) &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          other.midpoint == midpoint &&
          other.reverse == reverse &&
          other.clamp == clamp &&
          other.missingColor == missingColor &&
          other.label == label &&
          other.unit == unit &&
          other.showLegend == showLegend;

  @override
  int get hashCode => Object.hash(
    type,
    Object.hashAll(colors),
    Object.hashAll(thresholds),
    Object.hashAll(bandLabels),
    minimumValue,
    maximumValue,
    midpoint,
    reverse,
    clamp,
    missingColor,
    label,
    unit,
    showLegend,
  );
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
