// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'path_animation_style.dart';
import 'range_area_data_point.dart';
import 'range_area_style.dart';
import 'y_axis_config.dart';

/// A first-class Cartesian band bounded by paired low/high values.
///
/// There is no generated `withPoints` verb. [points] is force-excluded from
/// the fluent surface because a Range Area series' point list is not a value
/// a single setter can safely replace: every element must be a
/// [RangeAreaDataPoint] (the `copyWith` parameter is the wider
/// `List<ChartDataPoint>`), and the whole list must be STRICTLY increasing in
/// `x`. `withPoints([...])` would throw `ArgumentError` for any list that
/// broke either rule. Rebuild the series with the constructor — construction
/// stays the complete path — or edit intervals through [copyWith] where the
/// validation message names the offending index.
// The constructor validates in its BODY via validateConfiguration(), which
// names no parameter (it reads fields), so every emitted parameter is
// nominally in scope.
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(
  excluded: ['id', 'points'],
  bodyValidated: [
    BodyValidated(
      'validateConfiguration() re-runs the whole series check on every '
      'construction: it range-checks tension, fillOpacity and markerRadius, '
      'walks fillGradient colors/stops, and calls '
      'upperBoundaryStyle.validate() / lowerBoundaryStyle.validate() plus '
      'the pathAnimation timing checks. withUpperBoundaryStyle / '
      'withLowerBoundaryStyle / withFillGradient / withPathAnimation '
      'therefore throw ArgumentError for a nested config that is '
      'individually constructible but invalid inside this series. The check '
      'reads fields, not parameters, so surface_gen cannot narrow the scope '
      'below the whole class.',
    ),
  ],
)
final class RangeAreaChartSeries extends ChartSeries {
  RangeAreaChartSeries({
    required super.id,
    super.name,
    required List<RangeAreaDataPoint> points,
    super.color,
    super.metadata,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.tension = 0.25,
    this.fillOpacity = 0.28,
    this.fillGradient,
    this.borderMode = RangeAreaBorderMode.boundaries,
    this.upperBoundaryStyle = const RangeAreaBoundaryStyle(),
    this.lowerBoundaryStyle = const RangeAreaBoundaryStyle(),
    this.connectGaps = false,
    this.showBoundaryMarkers = false,
    this.markerRadius = 3,
    this.labelConfig = const RangeAreaLabelConfig(),
    this.hitTestMode = RangeAreaHitTestMode.band,
    this.pathAnimation = const PathAnimationStyle(),
  }) : super(
         points: List<RangeAreaDataPoint>.unmodifiable(points),
         style: SeriesStyle.rangeArea,
         isXOrdered: true,
       ) {
    validateConfiguration();
  }

  final LineInterpolation interpolation;
  final double tension;
  final double fillOpacity;
  final AreaGradient? fillGradient;
  final RangeAreaBorderMode borderMode;
  final RangeAreaBoundaryStyle upperBoundaryStyle;
  final RangeAreaBoundaryStyle lowerBoundaryStyle;
  final bool connectGaps;
  final bool showBoundaryMarkers;
  final double markerRadius;
  final RangeAreaLabelConfig labelConfig;
  final RangeAreaHitTestMode hitTestMode;
  final PathAnimationStyle pathAnimation;

  /// Typed, read-only view of the interval data owned by this series.
  ///
  /// [ChartSeries.points] is already immutable, so retaining one cast view
  /// avoids copying every interval on cursor moves and animation frames.
  late final List<RangeAreaDataPoint> intervals = points
      .cast<RangeAreaDataPoint>();

  /// Whether this immutable snapshot contains one or more explicit gaps.
  ///
  /// Cached after the first read so the interaction hot path can use the
  /// complete ordered list directly for the common contiguous case.
  late final bool hasGaps = intervals.any((point) => point.isGap);

  RangeAreaDataPoint intervalAt(int index) =>
      points[index] as RangeAreaDataPoint;

  void validateConfiguration() {
    if (!tension.isFinite || tension < 0 || tension > 1) {
      throw ArgumentError.value(
        tension,
        'tension',
        'must be finite and between 0 and 1',
      );
    }
    if (!fillOpacity.isFinite || fillOpacity < 0 || fillOpacity > 1) {
      throw ArgumentError.value(
        fillOpacity,
        'fillOpacity',
        'must be finite and between 0 and 1',
      );
    }
    if (!markerRadius.isFinite || markerRadius < 0) {
      throw ArgumentError.value(
        markerRadius,
        'markerRadius',
        'must be finite and non-negative',
      );
    }
    _validateGradient(fillGradient);
    upperBoundaryStyle.validate('upperBoundaryStyle');
    lowerBoundaryStyle.validate('lowerBoundaryStyle');
    _validateAnimation(pathAnimation);

    double? previousX;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point is! RangeAreaDataPoint) {
        throw ArgumentError.value(
          point.runtimeType,
          'points[$index]',
          'RangeAreaChartSeries requires RangeAreaDataPoint values',
        );
      }
      if (point.isGap) {
        RangeAreaDataPoint.validateGap(
          x: point.x,
          parameterName: 'points[$index]',
        );
      } else {
        RangeAreaDataPoint.validateInterval(
          x: point.x,
          low: point.low!,
          high: point.high!,
          parameterName: 'points[$index]',
        );
      }
      if (previousX != null && point.x <= previousX) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'must be strictly greater than points[${index - 1}].x ($previousX)',
        );
      }
      previousX = point.x;
    }
  }

  @override
  RangeAreaChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? tension,
    double? fillOpacity,
    AreaGradient? fillGradient,
    bool clearFillGradient = false,
    RangeAreaBorderMode? borderMode,
    RangeAreaBoundaryStyle? upperBoundaryStyle,
    RangeAreaBoundaryStyle? lowerBoundaryStyle,
    bool? connectGaps,
    bool? showBoundaryMarkers,
    double? markerRadius,
    RangeAreaLabelConfig? labelConfig,
    RangeAreaHitTestMode? hitTestMode,
    PathAnimationStyle? pathAnimation,
  }) {
    if (style != null && style != SeriesStyle.rangeArea) {
      throw ArgumentError.value(
        style,
        'style',
        'RangeAreaChartSeries style must remain rangeArea',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'RangeAreaChartSeries must remain X ordered',
      );
    }
    final nextPoints = points ?? this.points;
    for (var index = 0; index < nextPoints.length; index++) {
      if (nextPoints[index] is! RangeAreaDataPoint) {
        throw ArgumentError.value(
          nextPoints[index].runtimeType,
          'points[$index]',
          'RangeAreaChartSeries requires RangeAreaDataPoint values',
        );
      }
    }
    return RangeAreaChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: nextPoints.cast<RangeAreaDataPoint>(),
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      tension: tension ?? this.tension,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      fillGradient: clearFillGradient
          ? null
          : (fillGradient ?? this.fillGradient),
      borderMode: borderMode ?? this.borderMode,
      upperBoundaryStyle: upperBoundaryStyle ?? this.upperBoundaryStyle,
      lowerBoundaryStyle: lowerBoundaryStyle ?? this.lowerBoundaryStyle,
      connectGaps: connectGaps ?? this.connectGaps,
      showBoundaryMarkers: showBoundaryMarkers ?? this.showBoundaryMarkers,
      markerRadius: markerRadius ?? this.markerRadius,
      labelConfig: labelConfig ?? this.labelConfig,
      hitTestMode: hitTestMode ?? this.hitTestMode,
      pathAnimation: pathAnimation ?? this.pathAnimation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaChartSeries &&
          super == other &&
          interpolation == other.interpolation &&
          tension == other.tension &&
          fillOpacity == other.fillOpacity &&
          fillGradient == other.fillGradient &&
          borderMode == other.borderMode &&
          upperBoundaryStyle == other.upperBoundaryStyle &&
          lowerBoundaryStyle == other.lowerBoundaryStyle &&
          connectGaps == other.connectGaps &&
          showBoundaryMarkers == other.showBoundaryMarkers &&
          markerRadius == other.markerRadius &&
          labelConfig == other.labelConfig &&
          hitTestMode == other.hitTestMode &&
          pathAnimation == other.pathAnimation;

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    interpolation,
    tension,
    fillOpacity,
    fillGradient,
    borderMode,
    upperBoundaryStyle,
    lowerBoundaryStyle,
    connectGaps,
    showBoundaryMarkers,
    markerRadius,
    labelConfig,
    hitTestMode,
    pathAnimation,
  ]);

  static void _validateGradient(AreaGradient? gradient) {
    if (gradient == null) return;
    if (gradient.colors.length < 2) {
      throw ArgumentError.value(
        gradient.colors,
        'fillGradient.colors',
        'must contain at least two colors',
      );
    }
    final stops = gradient.stops;
    if (stops == null) return;
    if (stops.length != gradient.colors.length) {
      throw ArgumentError.value(
        stops,
        'fillGradient.stops',
        'must contain one stop for each color',
      );
    }
    double? previous;
    for (final (index, stop) in stops.indexed) {
      if (!stop.isFinite || stop < 0 || stop > 1) {
        throw ArgumentError.value(
          stop,
          'fillGradient.stops[$index]',
          'must be finite and between 0 and 1',
        );
      }
      if (previous != null && stop < previous) {
        throw ArgumentError.value(
          stop,
          'fillGradient.stops[$index]',
          'must be ordered',
        );
      }
      previous = stop;
    }
  }

  static void _validateAnimation(PathAnimationStyle animation) {
    for (final (name, timing) in [
      ('pathAnimation.entranceTiming', animation.entranceTiming),
      ('pathAnimation.dataUpdateTiming', animation.dataUpdateTiming),
    ]) {
      if (timing.delay.isNegative) {
        throw ArgumentError.value(
          timing.delay,
          '$name.delay',
          'must be non-negative',
        );
      }
      if (timing.duration?.isNegative ?? false) {
        throw ArgumentError.value(
          timing.duration,
          '$name.duration',
          'must be non-negative',
        );
      }
    }
  }

  @override
  String toString() =>
      'RangeAreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';
}
