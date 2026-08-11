import 'dart:ui' show Color;

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'radar_chart_config.dart';
import 'y_axis_config.dart';

/// One ordered quantitative profile rendered over shared radial categories.
@ChartSurface(
  excluded: ['id', 'points'],
  bodyValidated: [
    BodyValidated(
      '_validate() re-runs radarStyle.validate() on every construction, so '
      'withRadarStyle rejects nested style values that are invalid for a '
      'Radar series.',
    ),
  ],
)
class RadarChartSeries extends ChartSeries {
  RadarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    super.showInLegend,
    super.showTrackingAxisLabel,
    super.showInTrackingTooltip,
    this.radarStyle = const RadarSeriesStyle(),
  }) : super(style: SeriesStyle.radar, isXOrdered: true) {
    _validate();
  }

  /// Creates stable ordinal points from insertion-ordered categories.
  factory RadarChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    bool showInLegend = true,
    bool showTrackingAxisLabel = true,
    bool showInTrackingTooltip = true,
    RadarSeriesStyle radarStyle = const RadarSeriesStyle(),
  }) => RadarChartSeries(
    id: id,
    name: name,
    points: [
      for (final (index, entry) in values.entries.indexed)
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
        ),
    ],
    color: color,
    metadata: metadata,
    unit: unit,
    showInLegend: showInLegend,
    showTrackingAxisLabel: showTrackingAxisLabel,
    showInTrackingTooltip: showInTrackingTooltip,
    radarStyle: radarStyle,
  );

  final RadarSeriesStyle radarStyle;

  List<String> get categories =>
      List<String>.unmodifiable(points.map((point) => point.label!.trim()));

  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Series ID cannot be blank');
    }
    if (points.length < 3) {
      throw ArgumentError.value(
        points.length,
        'points',
        'Radar requires at least three categories',
      );
    }
    final categories = <String>{};
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite || point.x != index.toDouble()) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Radar X values must be stable zero-based ordinals',
        );
      }
      if (!point.y.isFinite || point.y < 0) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Radar values must be finite and non-negative',
        );
      }
      final category = point.label?.trim();
      if (category == null || category.isEmpty || !categories.add(category)) {
        throw ArgumentError.value(
          point.label,
          'points[$index].label',
          'Radar categories must be visible and unique',
        );
      }
    }
    radarStyle.validate();
  }

  @override
  RadarChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    bool clearUnit = false,
    bool? showInLegend,
    bool? showTrackingAxisLabel,
    bool? showInTrackingTooltip,
    RadarSeriesStyle? radarStyle,
  }) {
    if (style != null && style != SeriesStyle.radar) {
      throw ArgumentError.value(style, 'style', 'Radar series style is fixed');
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Radar category order must remain stable',
      );
    }
    if (annotations != null || yAxisId != null || yAxisConfig != null) {
      throw ArgumentError(
        'Radar uses RadarChartConfig axes and does not support Cartesian '
        'series annotations',
      );
    }
    return RadarChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      unit: clearUnit ? null : (unit ?? this.unit),
      showInLegend: showInLegend ?? this.showInLegend,
      showTrackingAxisLabel:
          showTrackingAxisLabel ?? this.showTrackingAxisLabel,
      showInTrackingTooltip:
          showInTrackingTooltip ?? this.showInTrackingTooltip,
      radarStyle: radarStyle ?? this.radarStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarChartSeries &&
          super == other &&
          radarStyle == other.radarStyle;

  @override
  int get hashCode => Object.hash(super.hashCode, radarStyle);
}
