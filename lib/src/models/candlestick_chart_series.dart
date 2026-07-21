// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../meta/chart_surface.dart';
import 'candlestick_chart_style.dart';
import 'candlestick_data_point.dart';
import 'candlestick_density_grouping.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'y_axis_config.dart';

/// A first-class Cartesian open-high-low-close series.
///
/// There is no generated `withPoints` verb. [points] is force-excluded from
/// the fluent surface because a candlestick series' point list is not a
/// value a single setter can safely replace: every element must be a
/// [CandlestickDataPoint] (the `copyWith` parameter is the wider
/// `List<ChartDataPoint>`), and the whole list must be STRICTLY increasing in
/// `x`. `withPoints([...])` threw `ArgumentError` for any list that broke
/// either rule. Rebuild the series with the constructor — construction stays
/// the complete path — or edit candles through [copyWith] where the
/// validation message names the offending index.
// The constructor validates in its BODY via validateConfiguration(), which
// names no parameter, so every emitted parameter is nominally in scope.
@ChartSurface(
  excluded: ['points'],
  bodyValidated: [
    BodyValidated(
      'validateConfiguration() re-runs candlestickStyle.validate(), '
      'animation.validate() and densityGrouping.validate() on every '
      'construction, so withCandlestickStyle / withAnimation / '
      'withDensityGrouping throw ArgumentError for a nested config that is '
      'individually constructible but invalid inside this series. The check '
      'reads fields, not parameters, so surface_gen cannot narrow the scope '
      'below the whole class.',
    ),
  ],
)
final class CandlestickChartSeries extends ChartSeries {
  CandlestickChartSeries({
    required super.id,
    super.name,
    required List<CandlestickDataPoint> points,
    super.color,
    super.metadata,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.candlestickStyle = const CandlestickChartStyle(),
    this.animation = const CandlestickAnimationStyle(),
    this.densityGrouping = const CandlestickDensityGrouping(),
  }) : super(
         points: List<CandlestickDataPoint>.unmodifiable(points),
         style: SeriesStyle.candlestick,
         isXOrdered: true,
       ) {
    validateConfiguration();
  }

  final CandlestickChartStyle candlestickStyle;
  final CandlestickAnimationStyle animation;
  final CandlestickDensityGrouping densityGrouping;

  List<CandlestickDataPoint> get candles =>
      List<CandlestickDataPoint>.unmodifiable(
        points.cast<CandlestickDataPoint>(),
      );

  CandlestickDataPoint candleAt(int index) =>
      points[index] as CandlestickDataPoint;

  /// Validates typed points, OHLC invariants, and strict source X ordering.
  void validateConfiguration() {
    candlestickStyle.validate();
    animation.validate();
    densityGrouping.validate();
    double? previousX;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point is! CandlestickDataPoint) {
        throw ArgumentError.value(
          point.runtimeType,
          'points[$index]',
          'CandlestickChartSeries requires CandlestickDataPoint values',
        );
      }
      CandlestickDataPoint.validateValues(
        x: point.x,
        open: point.open,
        high: point.high,
        low: point.low,
        close: point.close,
        parameterName: 'points[$index]',
      );
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
  CandlestickChartSeries copyWith({
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
    CandlestickChartStyle? candlestickStyle,
    CandlestickAnimationStyle? animation,
    CandlestickDensityGrouping? densityGrouping,
  }) {
    if (style != null && style != SeriesStyle.candlestick) {
      throw ArgumentError.value(
        style,
        'style',
        'CandlestickChartSeries style must remain candlestick',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'CandlestickChartSeries must remain X ordered',
      );
    }
    final nextPoints = points ?? this.points;
    for (var index = 0; index < nextPoints.length; index++) {
      if (nextPoints[index] is! CandlestickDataPoint) {
        throw ArgumentError.value(
          nextPoints[index].runtimeType,
          'points[$index]',
          'CandlestickChartSeries requires CandlestickDataPoint values',
        );
      }
    }
    return CandlestickChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: nextPoints.cast<CandlestickDataPoint>(),
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      candlestickStyle: candlestickStyle ?? this.candlestickStyle,
      animation: animation ?? this.animation,
      densityGrouping: densityGrouping ?? this.densityGrouping,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickChartSeries &&
          super == other &&
          other.candlestickStyle == candlestickStyle &&
          other.animation == animation &&
          other.densityGrouping == densityGrouping;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, candlestickStyle, animation, densityGrouping);

  @override
  String toString() =>
      'CandlestickChartSeries(id: $id, points: ${points.length})';
}
