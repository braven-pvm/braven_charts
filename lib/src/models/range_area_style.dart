// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import 'data_point_label_config.dart';
import 'range_area_data_point.dart';

/// Which edges of a Range Area receive a visible stroke.
enum RangeAreaBorderMode {
  /// Paint only the interval fill.
  none,

  /// Paint the upper and lower boundaries without vertical end caps.
  boundaries,

  /// Paint both boundaries and the vertical start/end sides.
  closed,
}

/// How pointer hit testing resolves a Range Area.
enum RangeAreaHitTestMode {
  /// The filled interval is interactive across its complete vertical span.
  band,

  /// Only proximity to the upper or lower boundary is interactive.
  nearestBoundary,
}

/// Interval measure rendered by Range Area point labels.
enum RangeAreaLabelValue { none, low, high, both, midpoint, span }

/// Typed value represented by one Range Area label.
enum RangeAreaLabelBoundary { low, high, midpoint, span }

/// Formatter payload for one low/high-aware Range Area label.
@immutable
class RangeAreaLabelDetails {
  const RangeAreaLabelDetails({
    required this.point,
    required this.boundary,
    required this.value,
    this.unit,
  });

  final RangeAreaDataPoint point;
  final RangeAreaLabelBoundary boundary;
  final double value;
  final String? unit;
}

typedef RangeAreaLabelFormatter = String Function(RangeAreaLabelDetails);

/// Portable label configuration for one Range Area series.
///
/// `formatter` has a generated `withFormatter` verb but no `clearFormatter`:
/// `copyWith` merges it with `??` and exposes no clear flag, so a label
/// formatter can be replaced but not removed once set. Drop back to the
/// generic formatter by rebuilding the config.
@immutable
@chartSurface
class RangeAreaLabelConfig {
  const RangeAreaLabelConfig({
    this.value = RangeAreaLabelValue.none,
    this.labels = const DataPointLabelConfig(),
    this.boundaryGap = 4,
    this.formatter,
  }) : assert(
         boundaryGap >= 0 && boundaryGap < double.infinity,
         'boundaryGap must be finite and non-negative',
       );

  /// Which typed interval value the labels display.
  final RangeAreaLabelValue value;

  /// Shared typography, collision, background, and placement options.
  final DataPointLabelConfig labels;

  /// Minimum separation between paired low/high labels.
  final double boundaryGap;

  /// Optional low/high-aware formatter used ahead of the generic formatter.
  final RangeAreaLabelFormatter? formatter;

  RangeAreaLabelConfig copyWith({
    RangeAreaLabelValue? value,
    DataPointLabelConfig? labels,
    double? boundaryGap,
    RangeAreaLabelFormatter? formatter,
  }) => RangeAreaLabelConfig(
    value: value ?? this.value,
    labels: labels ?? this.labels,
    boundaryGap: boundaryGap ?? this.boundaryGap,
    formatter: formatter ?? this.formatter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaLabelConfig &&
          value == other.value &&
          labels == other.labels &&
          boundaryGap == other.boundaryGap &&
          formatter == other.formatter;

  @override
  int get hashCode => Object.hash(value, labels, boundaryGap, formatter);
}

/// Stroke presentation for one Range Area boundary.
///
/// The constructor itself validates nothing: [validate] is called by the
/// OWNING series, so `withStrokeWidth(-1)` builds a boundary style happily
/// and the `ArgumentError` surfaces when the style is handed to
/// [RangeAreaChartSeries]. That coupling is modelled on the series, whose
/// generated verbs re-validate both boundaries.
@immutable
@chartSurface
class RangeAreaBoundaryStyle {
  const RangeAreaBoundaryStyle({
    this.visible = true,
    this.color,
    this.strokeWidth = 1.5,
    this.dashPattern = const [],
    this.glowRadius = 0,
  });

  final bool visible;

  /// Optional override; null derives the boundary from the series/theme color.
  final Color? color;

  final double strokeWidth;

  /// Alternating painted and skipped distances. Empty means solid.
  final List<double> dashPattern;

  final double glowRadius;

  void validate(String parameterName) {
    if (!strokeWidth.isFinite || strokeWidth < 0) {
      throw ArgumentError.value(
        strokeWidth,
        '$parameterName.strokeWidth',
        'must be finite and non-negative',
      );
    }
    if (!glowRadius.isFinite || glowRadius < 0) {
      throw ArgumentError.value(
        glowRadius,
        '$parameterName.glowRadius',
        'must be finite and non-negative',
      );
    }
    if (dashPattern.length.isOdd) {
      throw ArgumentError.value(
        dashPattern,
        '$parameterName.dashPattern',
        'must contain an even number of intervals',
      );
    }
    for (final (index, interval) in dashPattern.indexed) {
      if (!interval.isFinite || interval <= 0) {
        throw ArgumentError.value(
          interval,
          '$parameterName.dashPattern[$index]',
          'must be finite and greater than zero',
        );
      }
    }
  }

  RangeAreaBoundaryStyle copyWith({
    bool? visible,
    Color? color,
    bool clearColor = false,
    double? strokeWidth,
    List<double>? dashPattern,
    double? glowRadius,
  }) => RangeAreaBoundaryStyle(
    visible: visible ?? this.visible,
    color: clearColor ? null : (color ?? this.color),
    strokeWidth: strokeWidth ?? this.strokeWidth,
    dashPattern: dashPattern ?? this.dashPattern,
    glowRadius: glowRadius ?? this.glowRadius,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaBoundaryStyle &&
          visible == other.visible &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          listEquals(dashPattern, other.dashPattern) &&
          glowRadius == other.glowRadius;

  @override
  int get hashCode => Object.hash(
    visible,
    color,
    strokeWidth,
    Object.hashAll(dashPattern),
    glowRadius,
  );
}
