// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_chart_style.dart';
import '../models/candlestick_data_point.dart';
import '../models/candlestick_density_grouping.dart';
import '../models/category_axis_config.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_type.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/range_area_chart_series.dart';
import '../models/range_area_data_point.dart';
import '../models/radial_category_series.dart';
import '../models/radial_selection_style.dart';
import '../models/scatter_render_config.dart';
import '../models/segment_style.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Result of parsing an AI-generated chart configuration.
///
/// Contains all the components needed to build a [BravenChartPlus] widget.
class ChartBuildResult {
  const ChartBuildResult({
    required this.series,
    this.title,
    this.chartType,
    this.xAxisConfig,
    this.yAxisConfig,
    this.yAxes,
    this.interactionConfig,
    this.gridConfig,
    this.showLegend = true,
    this.height,
    this.chartId,
  });

  /// The data series to plot.
  final List<ChartSeries> series;

  /// Optional chart title.
  final String? title;

  /// Chart visualization type.
  final ChartType? chartType;

  /// X-axis configuration.
  final XAxisConfig? xAxisConfig;

  /// Primary Y-axis configuration (single-axis mode).
  final YAxisConfig? yAxisConfig;

  /// Multiple Y-axes for multi-axis mode.
  final List<YAxisConfig>? yAxes;

  /// Interaction settings.
  final InteractionConfig? interactionConfig;

  /// Grid line configuration.
  final GridConfig? gridConfig;

  /// Whether to show the legend.
  final bool showLegend;

  /// Suggested chart height in pixels.
  final double? height;

  /// Unique identifier for this chart instance.
  final String? chartId;
}

/// Converts AI-generated JSON configurations into BravenChartPlus components.
///
/// This class bridges the gap between LLM function calling outputs and the
/// strongly-typed BravenChartPlus API.
///
/// Example:
/// ```dart
/// // LLM returns JSON from create_chart tool
/// final json = {
///   'chart_type': 'line',
///   'series': [
///     {'id': 'temp', 'data': [{'x': 0, 'y': 20}, {'x': 1, 'y': 22}]}
///   ],
/// };
///
/// final result = ChartConfigBuilder.fromJson(json);
///
/// // Use in widget
/// BravenChartPlus(
///   series: result.series,
///   xAxisConfig: result.xAxisConfig,
///   yAxis: result.yAxisConfig,
/// );
/// ```
class ChartConfigBuilder {
  /// Parses a JSON configuration into chart components.
  ///
  /// The [json] parameter should match the schema defined in
  /// [ChartToolSchema.createChartTool].
  ///
  /// Throws [FormatException] if the JSON is invalid.
  static ChartBuildResult fromJson(Map<String, dynamic> json) {
    // Parse chart type first - needed for series style
    final chartTypeStr = json['chart_type'] as String?;
    final chartType = _parseChartType(chartTypeStr);
    final defaultStyle = _chartTypeToSeriesStyle(chartTypeStr);
    final styleJson = json['style'] as Map<String, dynamic>?;

    // Parse series (required)
    final seriesList = json['series'] as List<dynamic>?;
    if (seriesList == null || seriesList.isEmpty) {
      throw const FormatException('At least one series is required');
    }

    final series = seriesList
        .map(
          (s) => _parseSeries(
            s as Map<String, dynamic>,
            defaultStyle,
            chartStyle: styleJson,
          ),
        )
        .toList();

    final isRadial = chartType == ChartType.pie || chartType == ChartType.donut;
    if (isRadial) {
      if (series.length != 1 || series.single is! RadialCategorySeries) {
        throw const FormatException(
          'Radial charts require exactly one matching radial series and '
          'cannot mix series types.',
        );
      }
      if (json.containsKey('x_axis') || json.containsKey('y_axis')) {
        throw const FormatException(
          'Pie and Donut charts do not use x_axis or y_axis configuration.',
        );
      }
    } else if (series.any((value) => value is RadialCategorySeries)) {
      throw const FormatException(
        'Radial series require a matching radial chart_type and cannot mix '
        'with Cartesian series.',
      );
    }

    // Parse axes
    final xAxisConfig = isRadial
        ? null
        : _parseXAxisConfig(json['x_axis'] as Map<String, dynamic>?);
    final yAxisConfig = isRadial
        ? null
        : _parseYAxisConfig(json['y_axis'] as Map<String, dynamic>?);
    final categoryAxis = xAxisConfig?.categoryAxis;
    if (categoryAxis != null) {
      _validateCategoryCoordinates(series, categoryAxis);
    }

    // Check for multi-axis mode (series have different units)
    final units = series
        .map((s) => s.unit)
        .where((u) => u != null && u.isNotEmpty)
        .toSet();

    List<YAxisConfig>? yAxes;
    if (!isRadial && units.length > 1) {
      // Multi-axis mode: create Y-axes from series configurations
      yAxes = series
          .where((s) => s.yAxisConfig != null)
          .map((s) => s.yAxisConfig!)
          .toList();
    }

    // Parse interactions
    final interactionConfig = _parseInteractionConfig(
      json['interactions'] as Map<String, dynamic>?,
      isPie: isRadial,
    );

    // Parse style
    final gridConfig = isRadial
        ? const GridConfig(horizontal: false, vertical: false)
        : _parseGridConfig(styleJson);
    final showLegend = _parseShowLegend(styleJson);
    final height = (styleJson?['height'] as num?)?.toDouble();

    return ChartBuildResult(
      series: series,
      title: json['title'] as String?,
      chartType: chartType,
      xAxisConfig: xAxisConfig,
      yAxisConfig: yAxisConfig,
      yAxes: yAxes,
      interactionConfig: interactionConfig,
      gridConfig: gridConfig,
      showLegend: showLegend,
      height: height ?? 300,
      chartId: json['chart_id'] as String?,
    );
  }

  static ChartSeries _parseSeries(
    Map<String, dynamic> json,
    SeriesStyle? defaultStyle, {
    Map<String, dynamic>? chartStyle,
  }) {
    final id =
        json['id'] as String? ??
        'series_${DateTime.now().millisecondsSinceEpoch}';
    final name = json['name'] as String?;
    final colorStr = json['color'] as String?;
    final unit = json['unit'] as String?;
    final dataList = json['data'] as List<dynamic>? ?? [];
    final color = colorStr != null ? _parseColor(colorStr) : null;

    // Parse style before points because Candlestick has a dedicated OHLC
    // point contract and must never accept generic x/y data by accident.
    final typeValue = json['type'] ?? json['style'];
    if (typeValue != null && typeValue is! String) {
      throw const FormatException('Series type must be a string.');
    }
    final style = typeValue == null
        ? (defaultStyle ?? SeriesStyle.line)
        : _parseSeriesStyle(typeValue as String);
    if (typeValue != null && style == null) {
      throw FormatException('Unsupported series type "$typeValue".');
    }

    final points = style == SeriesStyle.candlestick
        ? _parseCandlestickPoints(dataList)
        : style == SeriesStyle.rangeArea
        ? _parseRangeAreaPoints(dataList)
        : dataList.indexed.map((entry) {
            final (index, d) = entry;
            final pointJson = d as Map<String, dynamic>;
            final x = pointJson['x'];
            final y = pointJson['y'];
            if (x is! num || y is! num) {
              throw const FormatException(
                'Every data point requires numeric x and y values.',
              );
            }
            final pointColor = pointJson['color'] is String
                ? _parseColor(pointJson['color'] as String)
                : null;
            final radiusValue = pointJson['radius'];
            if (radiusValue != null && radiusValue is! num) {
              throw const FormatException(
                'Pie radius values must be numeric when supplied.',
              );
            }
            return ChartDataPoint(
              x: x.toDouble(),
              y: y.toDouble(),
              pointKey: _parseOptionalPointKey(pointJson, index),
              label: pointJson['label'] as String?,
              timestamp: pointJson['timestamp'] != null
                  ? DateTime.tryParse(pointJson['timestamp'] as String)
                  : null,
              pointStyle: pointColor == null && radiusValue == null
                  ? null
                  : PointStyle(
                      color: pointColor,
                      size: (radiusValue as num?)?.toDouble(),
                    ),
            );
          }).toList();

    // Create Y-axis config if unit is specified
    YAxisConfig? yAxisConfig;
    if (unit != null && unit.isNotEmpty) {
      yAxisConfig = YAxisConfig(
        position: YAxisPosition.left,
        label: name ?? id,
        unit: unit,
      );
    }

    // Create the correct series type based on style (default to line)
    final effectiveStyle = style ?? SeriesStyle.line;
    return switch (effectiveStyle) {
      SeriesStyle.line => LineChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        interpolation: _parseLineInterpolation(chartStyle),
        strokeWidth: 2.0,
      ),
      SeriesStyle.area => AreaChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        interpolation: _parseLineInterpolation(chartStyle),
        fillOpacity: 0.3,
      ),
      SeriesStyle.rangeArea => RangeAreaChartSeries(
        id: id,
        name: name ?? id,
        points: points.cast<RangeAreaDataPoint>(),
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
      ),
      SeriesStyle.bar => _buildBarSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        chartStyle: chartStyle,
        seriesJson: json,
        dataList: dataList,
      ),
      SeriesStyle.scatter => ScatterChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        markerRadius:
            (chartStyle?['scatter_marker_radius'] as num?)?.toDouble() ?? 5,
        renderMode: _parseScatterRenderMode(chartStyle?['scatter_render_mode']),
        clusterConfig: _parseScatterClusterConfig(chartStyle),
        binConfig: _parseScatterBinConfig(chartStyle),
        densityConfig: _parseScatterDensityConfig(chartStyle),
      ),
      SeriesStyle.pie => _buildPieSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        chartStyle: chartStyle,
        seriesJson: json,
      ),
      SeriesStyle.donut => _buildDonutSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        chartStyle: chartStyle,
        seriesJson: json,
      ),
      SeriesStyle.polarColumn => throw const FormatException(
        'Polar Column is not yet part of the agentic chart schema; construct '
        'PolarColumnChartSeries through the public API.',
      ),
      SeriesStyle.candlestick => CandlestickChartSeries(
        id: id,
        name: name ?? id,
        points: points.cast<CandlestickDataPoint>(),
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        candlestickStyle: _parseCandlestickStyle(chartStyle),
        animation: _parseCandlestickAnimation(chartStyle),
        densityGrouping: _parseCandlestickDensityGrouping(chartStyle),
      ),
    };
  }

  /// Reads the shared `line_interpolation` style key into a
  /// [LineInterpolation] for Line and Area series.
  ///
  /// An absent key defaults to [LineInterpolation.linear], preserving the
  /// historical straight-line behavior; an unknown value is a hard
  /// [FormatException] like every other enum-valued key in this builder, so an
  /// agent that misspells the option is told rather than silently ignored.
  static LineInterpolation _parseLineInterpolation(
    Map<String, dynamic>? style,
  ) => switch (style?['line_interpolation']) {
    null || 'linear' => LineInterpolation.linear,
    'bezier' => LineInterpolation.bezier,
    'stepped' => LineInterpolation.stepped,
    'monotone' => LineInterpolation.monotone,
    final value => throw FormatException(
      'Unknown line_interpolation "$value".',
    ),
  };

  static List<CandlestickDataPoint> _parseCandlestickPoints(
    List<dynamic> data,
  ) => [
    for (var index = 0; index < data.length; index++)
      _parseCandlestickPoint(data[index], index),
  ];

  static List<RangeAreaDataPoint> _parseRangeAreaPoints(List<dynamic> data) => [
    for (var index = 0; index < data.length; index++)
      _parseRangeAreaPoint(data[index], index),
  ];

  static RangeAreaDataPoint _parseRangeAreaPoint(dynamic value, int index) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Range Area data point $index must be an object.');
    }

    final xValue = value['x'];
    if (xValue is! num || !xValue.isFinite) {
      throw FormatException(
        'Range Area data point $index requires a finite numeric x.',
      );
    }

    final timestamp = _parseOptionalTimestamp(
      value['timestamp'],
      family: 'Range Area',
      index: index,
    );
    final gapValue = value['gap'];
    if (gapValue != null && gapValue is! bool) {
      throw FormatException(
        'Range Area data point $index gap must be a boolean.',
      );
    }
    if (gapValue == true) {
      if (value.containsKey('low') ||
          value.containsKey('high') ||
          value.containsKey('y')) {
        throw FormatException(
          'Range Area gap $index cannot include low, high, or y.',
        );
      }
      return RangeAreaDataPoint.gap(
        x: xValue.toDouble(),
        pointKey: _parseOptionalPointKey(value, index),
        timestamp: timestamp,
        label: value['label'] as String?,
      );
    }

    if (value.containsKey('y')) {
      throw FormatException(
        'Range Area data point $index requires low and high; generic y is not supported.',
      );
    }
    final lowValue = value['low'];
    final highValue = value['high'];
    if (lowValue is! num || !lowValue.isFinite) {
      throw FormatException(
        'Range Area data point $index requires a finite numeric low or an explicit gap.',
      );
    }
    if (highValue is! num || !highValue.isFinite) {
      throw FormatException(
        'Range Area data point $index requires a finite numeric high or an explicit gap.',
      );
    }
    return RangeAreaDataPoint(
      x: xValue.toDouble(),
      pointKey: _parseOptionalPointKey(value, index),
      low: lowValue.toDouble(),
      high: highValue.toDouble(),
      timestamp: timestamp,
      label: value['label'] as String?,
    );
  }

  static DateTime? _parseOptionalTimestamp(
    dynamic value, {
    required String family,
    required int index,
  }) {
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(
        '$family data point $index timestamp must be ISO 8601.',
      );
    }
    final timestamp = DateTime.tryParse(value);
    if (timestamp == null) {
      throw FormatException(
        '$family data point $index timestamp must be ISO 8601.',
      );
    }
    return timestamp;
  }

  static String? _parseOptionalPointKey(Map<String, dynamic> value, int index) {
    final pointKey = value['point_key'];
    if (pointKey == null) return null;
    if (pointKey is! String || pointKey.isEmpty) {
      throw FormatException(
        'Data point $index point_key must be a non-empty string.',
      );
    }
    return pointKey;
  }

  static CandlestickDataPoint _parseCandlestickPoint(dynamic value, int index) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Candlestick data point $index must be an object.');
    }
    double requiredNumber(String key) {
      final number = value[key];
      if (number is! num || !number.isFinite) {
        throw FormatException(
          'Candlestick data point $index requires a finite numeric $key.',
        );
      }
      return number.toDouble();
    }

    final timestamp = _parseOptionalTimestamp(
      value['timestamp'],
      family: 'Candlestick',
      index: index,
    );
    return CandlestickDataPoint(
      x: requiredNumber('x'),
      pointKey: _parseOptionalPointKey(value, index),
      open: requiredNumber('open'),
      high: requiredNumber('high'),
      low: requiredNumber('low'),
      close: requiredNumber('close'),
      timestamp: timestamp,
      label: value['label'] as String?,
    );
  }

  static CandlestickChartStyle _parseCandlestickStyle(
    Map<String, dynamic>? json,
  ) => CandlestickChartStyle(
    bodyFillMode: switch (json?['candlestick_body_fill']) {
      'filled' => CandlestickBodyFillMode.filled,
      _ => CandlestickBodyFillMode.hollowRising,
    },
    bodyWidthFactor:
        (json?['candlestick_body_width_factor'] as num?)?.toDouble() ?? .7,
    bodyBorderWidth:
        (json?['candlestick_border_width'] as num?)?.toDouble() ?? 1,
    wickWidth: (json?['candlestick_wick_width'] as num?)?.toDouble() ?? 1,
    bodyCornerRadius:
        (json?['candlestick_corner_radius'] as num?)?.toDouble() ?? 0,
  );

  static CandlestickAnimationStyle _parseCandlestickAnimation(
    Map<String, dynamic>? json,
  ) => CandlestickAnimationStyle(
    mode: switch (json?['candlestick_animation_mode']) {
      'none' => CandlestickAnimationMode.none,
      _ => CandlestickAnimationMode.reveal,
    },
    staggerFraction:
        (json?['candlestick_animation_stagger'] as num?)?.toDouble() ?? 0,
  );

  static ScatterRenderMode _parseScatterRenderMode(Object? value) =>
      switch (value) {
        null || 'points' => ScatterRenderMode.points,
        'clusters' => ScatterRenderMode.clusters,
        'rectangular_bins' => ScatterRenderMode.rectangularBins,
        'hexbin' => ScatterRenderMode.hexbin,
        'density' => ScatterRenderMode.density,
        _ => throw FormatException('Unknown scatter_render_mode "$value".'),
      };

  static ScatterClusterConfig _parseScatterClusterConfig(
    Map<String, dynamic>? style,
  ) {
    try {
      final cellSize =
          (style?['scatter_cluster_cell_size'] as num?)?.toDouble() ?? 40;
      final minimumPointCount =
          (style?['scatter_cluster_minimum_points'] as num?)?.toInt() ?? 2;
      final minimumRadius =
          (style?['scatter_cluster_minimum_radius'] as num?)?.toDouble() ?? 8;
      final maximumRadius =
          (style?['scatter_cluster_maximum_radius'] as num?)?.toDouble() ?? 24;
      final showCountLabels =
          style?['scatter_cluster_show_labels'] as bool? ?? true;
      final labelMinimumPointCount =
          (style?['scatter_cluster_label_minimum_points'] as num?)?.toInt() ??
          2;
      final showZones = style?['scatter_cluster_show_zones'] as bool? ?? false;
      final zoneOpacity =
          (style?['scatter_cluster_zone_opacity'] as num?)?.toDouble() ?? 0.08;
      final drillOnTap =
          style?['scatter_cluster_drill_on_tap'] as bool? ?? true;
      final drillPadding =
          (style?['scatter_cluster_drill_padding'] as num?)?.toDouble() ?? 0.18;
      if (!cellSize.isFinite ||
          cellSize < 8 ||
          cellSize > 256 ||
          minimumPointCount < 2 ||
          !minimumRadius.isFinite ||
          !maximumRadius.isFinite ||
          minimumRadius <= 0 ||
          minimumRadius > maximumRadius ||
          maximumRadius > 128 ||
          labelMinimumPointCount < 2 ||
          !zoneOpacity.isFinite ||
          zoneOpacity < 0 ||
          zoneOpacity > 1 ||
          !drillPadding.isFinite ||
          drillPadding < 0 ||
          drillPadding > 1) {
        throw const FormatException(
          'Scatter cluster style values are outside supported bounds.',
        );
      }
      return ScatterClusterConfig(
        cellSize: cellSize,
        minimumPointCount: minimumPointCount,
        minimumRadius: minimumRadius,
        maximumRadius: maximumRadius,
        showCountLabels: showCountLabels,
        labelMinimumPointCount: labelMinimumPointCount,
        showZones: showZones,
        zoneOpacity: zoneOpacity,
        drillOnTap: drillOnTap,
        drillPadding: drillPadding,
      );
    } on TypeError {
      throw const FormatException(
        'Scatter cluster style values have invalid JSON types.',
      );
    } on AssertionError {
      throw const FormatException(
        'Scatter cluster style values are outside supported bounds.',
      );
    }
  }

  static ScatterBinConfig _parseScatterBinConfig(Map<String, dynamic>? style) {
    try {
      final cellSize =
          (style?['scatter_bin_cell_size'] as num?)?.toDouble() ?? 36;
      final gap = (style?['scatter_bin_gap'] as num?)?.toDouble() ?? 1;
      final minimumPointCount =
          (style?['scatter_bin_minimum_points'] as num?)?.toInt() ?? 1;
      final minimumOpacity =
          (style?['scatter_bin_minimum_opacity'] as num?)?.toDouble() ?? 0.2;
      final maximumOpacity =
          (style?['scatter_bin_maximum_opacity'] as num?)?.toDouble() ?? 0.95;
      final aggregate = switch (style?['scatter_bin_aggregate']) {
        null || 'count' => ScatterBinAggregate.count,
        'sum' => ScatterBinAggregate.sum,
        'mean' => ScatterBinAggregate.mean,
        'minimum' => ScatterBinAggregate.minimum,
        'maximum' => ScatterBinAggregate.maximum,
        'proportion' => ScatterBinAggregate.proportion,
        _ => throw const FormatException(
          'scatter_bin_aggregate must be count, sum, mean, minimum, maximum, or proportion.',
        ),
      };
      final valueSource = switch (style?['scatter_bin_value_source']) {
        null || 'y' => ScatterBinValueSource.y,
        'x' => ScatterBinValueSource.x,
        'magnitude' => ScatterBinValueSource.magnitude,
        'color_value' => ScatterBinValueSource.colorValue,
        'opacity_value' => ScatterBinValueSource.opacityValue,
        _ => throw const FormatException(
          'scatter_bin_value_source must be x, y, magnitude, color_value, or opacity_value.',
        ),
      };
      final showLabels = style?['scatter_bin_show_labels'] as bool? ?? false;
      final labelMinimumPointCount =
          (style?['scatter_bin_label_minimum_points'] as num?)?.toInt() ?? 10;
      if (!cellSize.isFinite ||
          cellSize < 12 ||
          cellSize > 256 ||
          !gap.isFinite ||
          gap < 0 ||
          gap > 16 ||
          minimumPointCount < 1 ||
          !minimumOpacity.isFinite ||
          minimumOpacity < 0 ||
          minimumOpacity > 1 ||
          !maximumOpacity.isFinite ||
          maximumOpacity < minimumOpacity ||
          maximumOpacity > 1 ||
          labelMinimumPointCount < 1) {
        throw const FormatException(
          'Scatter bin style values are outside supported bounds.',
        );
      }
      return ScatterBinConfig(
        cellSize: cellSize,
        gap: gap,
        minimumPointCount: minimumPointCount,
        minimumOpacity: minimumOpacity,
        maximumOpacity: maximumOpacity,
        aggregate: aggregate,
        valueSource: valueSource,
        showLabels: showLabels,
        labelMinimumPointCount: labelMinimumPointCount,
      );
    } on TypeError {
      throw const FormatException(
        'Scatter bin style values have invalid JSON types.',
      );
    }
  }

  static ScatterDensityConfig _parseScatterDensityConfig(
    Map<String, dynamic>? style,
  ) {
    try {
      final gridCellSize =
          (style?['scatter_density_grid_cell_size'] as num?)?.toDouble() ?? 8;
      final bandwidth =
          (style?['scatter_density_bandwidth'] as num?)?.toDouble() ?? 32;
      final contourCount =
          (style?['scatter_density_contour_count'] as num?)?.toInt() ?? 6;
      final minimumDensity =
          (style?['scatter_density_minimum'] as num?)?.toDouble() ?? 0.08;
      final minimumOpacity =
          (style?['scatter_density_minimum_opacity'] as num?)?.toDouble() ??
          0.28;
      final maximumOpacity =
          (style?['scatter_density_maximum_opacity'] as num?)?.toDouble() ??
          0.9;
      final lineWidth =
          (style?['scatter_density_line_width'] as num?)?.toDouble() ?? 1.5;
      final showPoints =
          style?['scatter_density_show_points'] as bool? ?? false;
      if (!gridCellSize.isFinite ||
          gridCellSize < 4 ||
          gridCellSize > 64 ||
          !bandwidth.isFinite ||
          bandwidth < 4 ||
          bandwidth > 256 ||
          contourCount < 2 ||
          contourCount > 12 ||
          !minimumDensity.isFinite ||
          minimumDensity <= 0 ||
          minimumDensity >= 1 ||
          !minimumOpacity.isFinite ||
          minimumOpacity < 0 ||
          minimumOpacity > 1 ||
          !maximumOpacity.isFinite ||
          maximumOpacity < minimumOpacity ||
          maximumOpacity > 1 ||
          !lineWidth.isFinite ||
          lineWidth <= 0 ||
          lineWidth > 12) {
        throw const FormatException(
          'Scatter density style values are outside supported bounds.',
        );
      }
      return ScatterDensityConfig(
        gridCellSize: gridCellSize,
        bandwidth: bandwidth,
        contourCount: contourCount,
        minimumDensity: minimumDensity,
        minimumOpacity: minimumOpacity,
        maximumOpacity: maximumOpacity,
        lineWidth: lineWidth,
        showPoints: showPoints,
      );
    } on TypeError {
      throw const FormatException(
        'Scatter density style values have invalid JSON types.',
      );
    }
  }

  static CandlestickDensityGrouping _parseCandlestickDensityGrouping(
    Map<String, dynamic>? json,
  ) => CandlestickDensityGrouping(
    enabled: json?['candlestick_density_grouping'] as bool? ?? false,
    targetGroupWidth:
        (json?['candlestick_target_group_width'] as num?)?.toDouble() ?? 5,
    minimumPointsPerGroup:
        (json?['candlestick_minimum_points_per_group'] as num?)?.toInt() ?? 2,
  );

  static void _validateCategoryCoordinates(
    List<ChartSeries> series,
    CategoryAxisConfig categoryAxis,
  ) {
    for (final chartSeries in series) {
      for (
        var pointIndex = 0;
        pointIndex < chartSeries.points.length;
        pointIndex++
      ) {
        final x = chartSeries.points[pointIndex].x;
        final categoryIndex = x.round();
        if ((x - categoryIndex).abs() > 0.000001 ||
            categoryIndex < 0 ||
            categoryIndex >= categoryAxis.categories.length) {
          throw FormatException(
            'Data point $pointIndex in series "${chartSeries.id}" has x=$x, '
            'which does not map to a configured category index.',
          );
        }
      }
    }
  }

  static DonutChartSeries _buildDonutSeries({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color? color,
    required String? unit,
    required Map<String, dynamic>? chartStyle,
    required Map<String, dynamic> seriesJson,
  }) {
    try {
      final radialStyle = _parsePieChartStyle(chartStyle);
      return DonutChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        unit: unit,
        donutStyle: DonutChartStyle.fromRadialStyle(
          radialStyle,
          innerRadiusFactor:
              (chartStyle?['donut_inner_radius_factor'] as num?)?.toDouble() ??
              0.58,
          sweepAngleDegrees:
              (chartStyle?['donut_sweep_angle'] as num?)?.toDouble() ?? 360,
        ),
        selectionStyle: _parseRadialSelectionStyle(chartStyle),
        centerContent: _parseDonutCenterContent(chartStyle),
        dataLabels: _parsePieDataLabels(chartStyle),
        sliceRadiusConfig: _parsePieSliceRadiusConfig(
          points,
          seriesJson: seriesJson,
          chartStyle: chartStyle,
        ),
        sliceGroupingConfig: _parseRadialSliceGroupingConfig(chartStyle),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid donut series "$id": ${error.message}');
    }
  }

  static BarChartSeries _buildBarSeries({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color? color,
    required String? unit,
    required YAxisConfig? yAxisConfig,
    required Map<String, dynamic>? chartStyle,
    required Map<String, dynamic> seriesJson,
    required List<dynamic> dataList,
  }) {
    final style = <String, dynamic>{
      ...?chartStyle,
      for (final entry in seriesJson.entries)
        if (entry.key.startsWith('bar_')) entry.key: entry.value,
    };
    final layout = _parseBarLayout(style['bar_layout']);
    final rangeStarts = _barPointValues(dataList, 'bar_start');
    final targetValues = _barPointValues(dataList, 'bar_target');
    final errorLowerValues = _barPointValues(dataList, 'bar_error_lower');
    final errorUpperValues = _barPointValues(dataList, 'bar_error_upper');
    if (errorLowerValues.isNotEmpty != errorUpperValues.isNotEmpty) {
      throw FormatException(
        'Bar series "$id" must provide bar_error_lower and '
        'bar_error_upper together.',
      );
    }
    if (rangeStarts.isNotEmpty &&
        (layout == BarLayoutMode.stacked ||
            layout == BarLayoutMode.normalizedStacked ||
            layout == BarLayoutMode.divergingStacked ||
            layout == BarLayoutMode.waterfall)) {
      throw FormatException(
        'Bar series "$id" cannot combine bar_start values with '
        '${style['bar_layout']}.',
      );
    }

    final waterfallTotals = <int>{};
    for (var index = 0; index < dataList.length; index++) {
      final point = dataList[index] as Map<String, dynamic>;
      final isTotal = point['bar_total'];
      if (isTotal != null && isTotal is! bool) {
        throw FormatException(
          'Bar data point $index in "$id" has a non-boolean bar_total.',
        );
      }
      if (isTotal == true) waterfallTotals.add(index);
    }

    try {
      return BarChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        isXOrdered: layout == BarLayoutMode.waterfall,
        barWidthPercent:
            (style['bar_width_percent'] as num?)?.toDouble() ?? 0.8,
        minWidth: (style['bar_min_width'] as num?)?.toDouble() ?? 4,
        maxWidth: (style['bar_max_width'] as num?)?.toDouble() ?? 100,
        barGap: (style['bar_gap'] as num?)?.toDouble() ?? 2,
        orientation: _parseBarOrientation(style['bar_orientation']),
        layoutMode: layout,
        groupId: seriesJson['bar_group_id'] as String?,
        divergingRole: _parseBarDivergingRole(seriesJson['bar_diverging_role']),
        divergingStyle: _parseBarDivergingStyle(style),
        overlayWidthFactor:
            (seriesJson['bar_overlay_width_factor'] as num?)?.toDouble() ?? 1,
        overlayOffsetFactor:
            (seriesJson['bar_overlay_offset_factor'] as num?)?.toDouble() ?? 0,
        baselineValue: (style['bar_baseline'] as num?)?.toDouble() ?? 0,
        rangeStartValues: rangeStarts,
        waterfallTotalIndices: waterfallTotals,
        waterfallStyle: _parseBarWaterfallStyle(style),
        minBarLength: (style['bar_minimum_length'] as num?)?.toDouble() ?? 0,
        barStyle: _parseBarChartStyle(style),
        trackStyle: _parseBarTrackStyle(style),
        lollipopStyle: _parseBarLollipopStyle(style),
        bulletStyle: _parseBarBulletStyle(style),
        targetValues: targetValues,
        targetMarkerStyle: _parseBarTargetMarkerStyle(style),
        errorLowerValues: errorLowerValues,
        errorUpperValues: errorUpperValues,
        errorBarStyle: _parseBarErrorBarStyle(style),
        labelStyle: _parseBarLabelStyle(style),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid bar series "$id": ${error.message}');
    }
  }

  static List<double?> _barPointValues(List<dynamic> data, String key) {
    if (!data.any(
      (value) => (value as Map<String, dynamic>).containsKey(key),
    )) {
      return const [];
    }
    return [
      for (var index = 0; index < data.length; index++)
        switch ((data[index] as Map<String, dynamic>)[key]) {
          null => null,
          final num value => value.toDouble(),
          _ => throw FormatException(
            'Bar data point $index has a non-numeric $key.',
          ),
        },
    ];
  }

  static BarLayoutMode _parseBarLayout(Object? value) => switch (value) {
    null || 'grouped' => BarLayoutMode.grouped,
    'overlaid' => BarLayoutMode.overlaid,
    'stacked' => BarLayoutMode.stacked,
    'normalized_stacked' => BarLayoutMode.normalizedStacked,
    'diverging_stacked' => BarLayoutMode.divergingStacked,
    'waterfall' => BarLayoutMode.waterfall,
    _ => throw FormatException('Unknown bar_layout "$value".'),
  };

  static BarDivergingRole _parseBarDivergingRole(Object? value) =>
      switch (value) {
        null || 'positive' => BarDivergingRole.positive,
        'negative' => BarDivergingRole.negative,
        'neutral' => BarDivergingRole.neutral,
        _ => throw FormatException('Unknown bar_diverging_role "$value".'),
      };

  static BarDivergingStyle _parseBarDivergingStyle(
    Map<String, dynamic> json,
  ) => BarDivergingStyle(
    showCenterLine: json['bar_diverging_center_line_show'] as bool? ?? true,
    centerLineColor:
        _optionalNamedColor(json, 'bar_diverging_center_line_color') ??
        const Color(0xFF64748B),
    centerLineWidth:
        (json['bar_diverging_center_line_width'] as num?)?.toDouble() ?? 1.25,
    centerLineOpacity:
        (json['bar_diverging_center_line_opacity'] as num?)?.toDouble() ?? 0.7,
  );

  static BarOrientation _parseBarOrientation(Object? value) => switch (value) {
    null || 'vertical' => BarOrientation.vertical,
    'horizontal' => BarOrientation.horizontal,
    _ => throw FormatException('Unknown bar_orientation "$value".'),
  };

  static BarChartStyle _parseBarChartStyle(Map<String, dynamic> json) =>
      BarChartStyle(
        cornerRadius: (json['bar_corner_radius'] as num?)?.toDouble() ?? 0,
        cornerRadiusPolicy: switch (json['bar_corner_policy']) {
          null || 'value_end' => BarCornerRadiusPolicy.valueEnd,
          'all' => BarCornerRadiusPolicy.all,
          final value => throw FormatException(
            'Unknown bar_corner_policy "$value".',
          ),
        },
        gradient: _parseBarGradient(json),
        pattern: _parseBarPattern(json),
        border: _parseBarBorder(json),
        opacity: (json['bar_opacity'] as num?)?.toDouble() ?? 1,
        interaction: _parseBarInteractionStyle(json),
        animationMode: switch (json['bar_animation_mode']) {
          null || 'grow' => BarAnimationMode.grow,
          'none' => BarAnimationMode.none,
          final value => throw FormatException(
            'Unknown bar_animation_mode "$value".',
          ),
        },
        motion: _parseBarMotionStyle(json),
      );

  static BarPatternStyle? _parseBarPattern(Map<String, dynamic> json) {
    final patternValue = json['bar_pattern'];
    if (patternValue == null || patternValue == 'none') return null;
    final spacingValue = json['bar_pattern_spacing'];
    final strokeWidthValue = json['bar_pattern_stroke_width'];
    final opacityValue = json['bar_pattern_opacity'];
    if (spacingValue != null && spacingValue is! num) {
      throw const FormatException('bar_pattern_spacing must be numeric.');
    }
    if (strokeWidthValue != null && strokeWidthValue is! num) {
      throw const FormatException('bar_pattern_stroke_width must be numeric.');
    }
    if (opacityValue != null && opacityValue is! num) {
      throw const FormatException('bar_pattern_opacity must be numeric.');
    }
    final spacing = (spacingValue as num?)?.toDouble() ?? 8;
    final strokeWidth = (strokeWidthValue as num?)?.toDouble() ?? 1.5;
    final opacity = (opacityValue as num?)?.toDouble() ?? 0.55;
    if (spacing <= 0 || strokeWidth <= 0 || opacity < 0 || opacity > 1) {
      throw const FormatException(
        'Bar pattern spacing and stroke width must be positive and opacity must be between 0 and 1.',
      );
    }
    return BarPatternStyle(
      pattern: switch (patternValue) {
        'diagonal_up' => BarFillPattern.diagonalUp,
        'diagonal_down' => BarFillPattern.diagonalDown,
        'crosshatch' => BarFillPattern.crosshatch,
        'horizontal' => BarFillPattern.horizontal,
        'vertical' => BarFillPattern.vertical,
        final value => throw FormatException('Unknown bar_pattern "$value".'),
      },
      color: _optionalNamedColor(json, 'bar_pattern_color'),
      spacing: spacing,
      strokeWidth: strokeWidth,
      opacity: opacity,
    );
  }

  static BarMotionStyle _parseBarMotionStyle(Map<String, dynamic> json) {
    final staggerValue = json['bar_animation_stagger'];
    if (staggerValue != null && staggerValue is! num) {
      throw const FormatException(
        'bar_animation_stagger must be a numeric fraction.',
      );
    }
    final stagger = (staggerValue as num?)?.toDouble() ?? 0;
    if (stagger < 0 || stagger >= 1) {
      throw const FormatException(
        'bar_animation_stagger must be at least 0 and less than 1.',
      );
    }
    return BarMotionStyle(
      order: switch (json['bar_animation_order']) {
        null || 'together' => BarAnimationOrder.together,
        'forward' => BarAnimationOrder.forward,
        'reverse' => BarAnimationOrder.reverse,
        'center_out' => BarAnimationOrder.centerOut,
        'edges_in' => BarAnimationOrder.edgesIn,
        final value => throw FormatException(
          'Unknown bar_animation_order "$value".',
        ),
      },
      staggerFraction: stagger,
    );
  }

  static BarGradient? _parseBarGradient(Map<String, dynamic> json) {
    final colorsValue = json['bar_gradient_colors'];
    if (colorsValue == null) return null;
    if (colorsValue is! List || colorsValue.length < 2) {
      throw const FormatException(
        'bar_gradient_colors requires at least two colors.',
      );
    }
    final colors = [
      for (final value in colorsValue)
        if (value is String)
          _requiredColor(value, 'bar_gradient_colors')
        else
          throw const FormatException(
            'bar_gradient_colors entries must be color strings.',
          ),
    ];
    final stopsValue = json['bar_gradient_stops'];
    final stops = stopsValue == null
        ? null
        : [
            for (final value in stopsValue as List<dynamic>)
              if (value is num)
                value.toDouble()
              else
                throw const FormatException(
                  'bar_gradient_stops entries must be numeric.',
                ),
          ];
    if (stops != null && stops.length != colors.length) {
      throw const FormatException(
        'bar_gradient_stops must align with bar_gradient_colors.',
      );
    }
    return BarGradient(colors: colors, stops: stops);
  }

  static BarBorderStyle? _parseBarBorder(Map<String, dynamic> json) {
    final color = json['bar_border_color'];
    final width = json['bar_border_width'];
    if (color == null && width == null) return null;
    return BarBorderStyle(
      color: color is String
          ? _requiredColor(color, 'bar_border_color')
          : const Color(0xFF334155),
      width: (width as num?)?.toDouble() ?? 1,
    );
  }

  static BarInteractionStyle _parseBarInteractionStyle(
    Map<String, dynamic> json,
  ) => BarInteractionStyle(
    hoverColor: _optionalNamedColor(json, 'bar_hover_color'),
    hoverOpacity: (json['bar_hover_opacity'] as num?)?.toDouble() ?? 0.12,
    hoverBorderWidth: (json['bar_hover_border_width'] as num?)?.toDouble() ?? 2,
    pressedColor:
        _optionalNamedColor(json, 'bar_pressed_color') ??
        const Color(0xFF000000),
    pressedOpacity: (json['bar_pressed_opacity'] as num?)?.toDouble() ?? 0.16,
    selectionColor: _optionalNamedColor(json, 'bar_selection_color'),
    selectionOpacity:
        (json['bar_selection_opacity'] as num?)?.toDouble() ?? 0.14,
    selectionBorderWidth:
        (json['bar_selection_border_width'] as num?)?.toDouble() ?? 2.5,
    focusColor: _optionalNamedColor(json, 'bar_focus_color'),
    focusBorderWidth:
        (json['bar_focus_border_width'] as num?)?.toDouble() ?? 2.5,
    focusGap: (json['bar_focus_gap'] as num?)?.toDouble() ?? 3,
    dimmedOpacity: (json['bar_dimmed_opacity'] as num?)?.toDouble() ?? 0.42,
  );

  static BarTrackStyle? _parseBarTrackStyle(Map<String, dynamic> json) {
    final enabled = json['bar_track_enabled'] as bool?;
    final colorValue = json['bar_track_color'];
    if (enabled != true && colorValue == null) return null;
    return BarTrackStyle(
      color: colorValue is String
          ? _requiredColor(colorValue, 'bar_track_color')
          : const Color(0xFFE5E7EB),
      value: (json['bar_track_value'] as num?)?.toDouble(),
      opacity: (json['bar_track_opacity'] as num?)?.toDouble() ?? 1,
      cornerRadius: (json['bar_track_corner_radius'] as num?)?.toDouble(),
    );
  }

  static BarLollipopStyle? _parseBarLollipopStyle(Map<String, dynamic> json) {
    final enabled = json['bar_lollipop_enabled'] as bool?;
    if (enabled != true) return null;
    final borderColor = _optionalNamedColor(
      json,
      'bar_lollipop_head_border_color',
    );
    final borderWidth =
        (json['bar_lollipop_head_border_width'] as num?)?.toDouble() ?? 0;
    return BarLollipopStyle(
      stemWidth: (json['bar_lollipop_stem_width'] as num?)?.toDouble() ?? 3,
      headRadius: (json['bar_lollipop_head_radius'] as num?)?.toDouble() ?? 7,
      stemColor: _optionalNamedColor(json, 'bar_lollipop_stem_color'),
      headColor: _optionalNamedColor(json, 'bar_lollipop_head_color'),
      headBorder: borderColor == null && borderWidth == 0
          ? null
          : BarBorderStyle(
              color: borderColor ?? const Color(0xFF334155),
              width: borderWidth,
            ),
    );
  }

  static BarBulletStyle? _parseBarBulletStyle(Map<String, dynamic> json) {
    final rawRanges = json['bar_bullet_ranges'];
    if (rawRanges == null) return null;
    if (rawRanges is! List || rawRanges.isEmpty) {
      throw const FormatException(
        'bar_bullet_ranges must be a non-empty array.',
      );
    }
    return BarBulletStyle(
      ranges: [
        for (var index = 0; index < rawRanges.length; index++)
          if (rawRanges[index] case final Map rawRange)
            _parseBarBulletRange(rawRange, index)
          else
            throw FormatException(
              'bar_bullet_ranges[$index] must be an object.',
            ),
      ],
      measureThicknessFactor:
          (json['bar_bullet_measure_thickness'] as num?)?.toDouble() ?? 0.45,
      cornerRadius: (json['bar_bullet_corner_radius'] as num?)?.toDouble() ?? 3,
    );
  }

  static BarBulletRange _parseBarBulletRange(Map rawRange, int index) {
    final range = Map<String, dynamic>.from(rawRange);
    final end = range['end'];
    final color = range['color'];
    final label = range['label'];
    if (end is! num) {
      throw FormatException('bar_bullet_ranges[$index].end must be numeric.');
    }
    if (color is! String) {
      throw FormatException(
        'bar_bullet_ranges[$index].color must be a color string.',
      );
    }
    if (label != null && label is! String) {
      throw FormatException(
        'bar_bullet_ranges[$index].label must be a string.',
      );
    }
    return BarBulletRange(
      endValue: end.toDouble(),
      color: _requiredColor(color, 'bar_bullet_ranges[$index].color'),
      label: label as String?,
    );
  }

  static BarTargetMarkerStyle _parseBarTargetMarkerStyle(
    Map<String, dynamic> json,
  ) => BarTargetMarkerStyle(
    color: _optionalNamedColor(json, 'bar_target_color'),
    width: (json['bar_target_width'] as num?)?.toDouble() ?? 2,
    lengthFactor: (json['bar_target_length_factor'] as num?)?.toDouble() ?? 1.3,
    opacity: (json['bar_target_opacity'] as num?)?.toDouble() ?? 1,
  );

  static BarErrorBarStyle _parseBarErrorBarStyle(Map<String, dynamic> json) =>
      BarErrorBarStyle(
        color: _optionalNamedColor(json, 'bar_error_color'),
        width: (json['bar_error_width'] as num?)?.toDouble() ?? 1.5,
        capLengthFactor:
            (json['bar_error_cap_length_factor'] as num?)?.toDouble() ?? 0.6,
        opacity: (json['bar_error_opacity'] as num?)?.toDouble() ?? 1,
      );

  static BarWaterfallStyle _parseBarWaterfallStyle(
    Map<String, dynamic> json,
  ) => BarWaterfallStyle(
    increaseColor: _optionalNamedColor(json, 'bar_waterfall_increase_color'),
    decreaseColor: _optionalNamedColor(json, 'bar_waterfall_decrease_color'),
    totalColor: _optionalNamedColor(json, 'bar_waterfall_total_color'),
    connector: BarWaterfallConnectorStyle(
      show: json['bar_waterfall_connector_show'] as bool? ?? true,
      color:
          _optionalNamedColor(json, 'bar_waterfall_connector_color') ??
          const Color(0xFF9CA3AF),
      width: (json['bar_waterfall_connector_width'] as num?)?.toDouble() ?? 1,
    ),
  );

  static BarLabelStyle _parseBarLabelStyle(
    Map<String, dynamic> json,
  ) => BarLabelStyle(
    show: json['bar_labels_show'] as bool? ?? false,
    position: switch (json['bar_label_position']) {
      null || 'auto' => BarLabelPosition.auto,
      'inside_end' => BarLabelPosition.insideEnd,
      'inside_center' => BarLabelPosition.insideCenter,
      'outside_end' => BarLabelPosition.outsideEnd,
      'range_ends' => BarLabelPosition.rangeEnds,
      final value => throw FormatException(
        'Unknown bar_label_position "$value".',
      ),
    },
    valueMode: switch (json['bar_label_value_mode']) {
      null || 'value' => BarLabelValueMode.value,
      'range' => BarLabelValueMode.range,
      'percentage' => BarLabelValueMode.percentage,
      'waterfall' => BarLabelValueMode.waterfall,
      final value => throw FormatException(
        'Unknown bar_label_value_mode "$value".',
      ),
    },
    color: _optionalNamedColor(json, 'bar_label_color'),
    fontSize: (json['bar_label_font_size'] as num?)?.toDouble() ?? 10,
    fontWeight: _parseBarLabelFontWeight(json['bar_label_font_weight']),
    showUnit: json['bar_label_show_unit'] as bool? ?? false,
    padding: (json['bar_label_padding'] as num?)?.toDouble() ?? 4,
    collisionPolicy: switch (json['bar_label_collision']) {
      null || 'none' => BarLabelCollisionPolicy.none,
      'reposition' => BarLabelCollisionPolicy.reposition,
      'hide' => BarLabelCollisionPolicy.hide,
      final value => throw FormatException(
        'Unknown bar_label_collision "$value".',
      ),
    },
    plotEdgeAware: json['bar_label_plot_edge_aware'] as bool? ?? true,
    collisionPadding:
        (json['bar_label_collision_padding'] as num?)?.toDouble() ?? 2,
    backgroundColor: _optionalNamedColor(json, 'bar_label_background_color'),
    borderColor: _optionalNamedColor(json, 'bar_label_border_color'),
    borderWidth: (json['bar_label_border_width'] as num?)?.toDouble() ?? 0,
    borderRadius: (json['bar_label_border_radius'] as num?)?.toDouble() ?? 4,
    backgroundPadding:
        (json['bar_label_background_padding'] as num?)?.toDouble() ?? 3,
    callout: BarLabelCalloutStyle(
      show: json['bar_label_callout_show'] as bool? ?? false,
      color: _optionalNamedColor(json, 'bar_label_callout_color'),
      width: (json['bar_label_callout_width'] as num?)?.toDouble() ?? 1,
      minimumLength:
          (json['bar_label_callout_minimum_length'] as num?)?.toDouble() ?? 4,
    ),
    showStackTotal: json['bar_label_show_stack_total'] as bool? ?? false,
  );

  static FontWeight _parseBarLabelFontWeight(Object? value) {
    final weight = value == null ? 600 : (value as num).toInt();
    return FontWeight.values.firstWhere(
      (candidate) => candidate.value == weight,
      orElse: () => throw const FormatException(
        'bar_label_font_weight must be 100 through 900.',
      ),
    );
  }

  static Color? _optionalNamedColor(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key must be a color string.');
    }
    return _requiredColor(value, key);
  }

  static Color _requiredColor(String value, String field) {
    final color = _parseColor(value);
    if (color == null) throw FormatException('Invalid $field color "$value".');
    return color;
  }

  static DonutCenterContent _parseDonutCenterContent(
    Map<String, dynamic>? json,
  ) {
    if (json == null) return DonutCenterContent.hidden;
    final modeValue = json['donut_center_value_mode'];
    final label = json['donut_center_label'] as String?;
    final customValue = json['donut_center_custom_value'] as String?;
    final hasCenterInput =
        modeValue != null || label != null || customValue != null;
    return DonutCenterContent(
      isVisible: json['donut_center_visible'] as bool? ?? hasCenterInput,
      label: label,
      valueMode: switch (modeValue) {
        null || 'total' => DonutCenterValueMode.total,
        'selected_value' => DonutCenterValueMode.selectedValue,
        'selected_or_total' => DonutCenterValueMode.selectedOrTotal,
        'custom' => DonutCenterValueMode.custom,
        final value => throw FormatException(
          'Unknown donut_center_value_mode "$value".',
        ),
      },
      customValue: customValue,
    );
  }

  static PieChartSeries _buildPieSeries({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color? color,
    required String? unit,
    required Map<String, dynamic>? chartStyle,
    required Map<String, dynamic> seriesJson,
  }) {
    try {
      return PieChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        unit: unit,
        pieStyle: _parsePieChartStyle(chartStyle),
        selectionStyle: _parseRadialSelectionStyle(chartStyle),
        dataLabels: _parsePieDataLabels(chartStyle),
        sliceRadiusConfig: _parsePieSliceRadiusConfig(
          points,
          seriesJson: seriesJson,
          chartStyle: chartStyle,
        ),
        sliceGroupingConfig: _parseRadialSliceGroupingConfig(chartStyle),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid pie series "$id": ${error.message}');
    }
  }

  static PieSliceRadiusConfig? _parsePieSliceRadiusConfig(
    List<ChartDataPoint> points, {
    required Map<String, dynamic> seriesJson,
    required Map<String, dynamic>? chartStyle,
  }) {
    if (!points.any((point) => point.pointStyle?.size != null)) return null;
    const defaults = PieSliceRadiusConfig();
    return PieSliceRadiusConfig(
      minimumFactor:
          (chartStyle?['pie_radius_minimum_factor'] as num?)?.toDouble() ??
          defaults.minimumFactor,
      scale: switch (chartStyle?['pie_radius_scale']) {
        null || 'area' => PieSliceRadiusScale.area,
        'linear' => PieSliceRadiusScale.linear,
        final value => throw FormatException(
          'Unknown pie_radius_scale "$value".',
        ),
      },
      label: seriesJson['radius_label'] as String? ?? defaults.label,
      unit: seriesJson['radius_unit'] as String?,
    );
  }

  static RadialSliceGroupingConfig? _parseRadialSliceGroupingConfig(
    Map<String, dynamic>? json,
  ) {
    if (json == null ||
        !json.keys.any((key) => key.startsWith('pie_grouping_'))) {
      return null;
    }
    return RadialSliceGroupingConfig(
      minimumShare:
          (json['pie_grouping_minimum_share'] as num?)?.toDouble() ?? 0.05,
      minimumSourceCount:
          (json['pie_grouping_minimum_source_count'] as num?)?.toInt() ?? 2,
      label: json['pie_grouping_label'] as String? ?? 'Other',
      color: switch (json['pie_grouping_color']) {
        final String value => _parseColor(value),
        _ => null,
      },
    );
  }

  static ChartType? _parseChartType(String? type) {
    return switch (type?.toLowerCase()) {
      'line' => ChartType.line,
      'area' => ChartType.area,
      'bar' => ChartType.bar,
      'scatter' => ChartType.scatter,
      'candlestick' => ChartType.candlestick,
      'pie' => ChartType.pie,
      'donut' => ChartType.donut,
      _ => null,
    };
  }

  static SeriesStyle? _chartTypeToSeriesStyle(String? type) {
    return switch (type?.toLowerCase()) {
      'line' => SeriesStyle.line,
      'area' => SeriesStyle.area,
      'bar' => SeriesStyle.bar,
      'scatter' => SeriesStyle.scatter,
      'rangearea' || 'range_area' || 'range-area' => SeriesStyle.rangeArea,
      'candlestick' => SeriesStyle.candlestick,
      'pie' => SeriesStyle.pie,
      'donut' => SeriesStyle.donut,
      _ => SeriesStyle.line, // Default to line
    };
  }

  static SeriesStyle? _parseSeriesStyle(String? style) {
    return switch (style?.toLowerCase()) {
      'line' => SeriesStyle.line,
      'area' => SeriesStyle.area,
      'bar' => SeriesStyle.bar,
      'scatter' => SeriesStyle.scatter,
      'rangearea' || 'range_area' || 'range-area' => SeriesStyle.rangeArea,
      'candlestick' => SeriesStyle.candlestick,
      'pie' => SeriesStyle.pie,
      'donut' => SeriesStyle.donut,
      _ => null,
    };
  }

  static XAxisConfig? _parseXAxisConfig(Map<String, dynamic>? json) {
    if (json == null) return null;

    final categoriesValue = json['categories'];
    CategoryAxisConfig? categoryAxis;
    if (categoriesValue != null) {
      if (categoriesValue is! List ||
          categoriesValue.isEmpty ||
          categoriesValue.any((value) => value is! String || value.isEmpty)) {
        throw const FormatException(
          'x_axis.categories must be a non-empty array of non-empty strings.',
        );
      }
      categoryAxis = CategoryAxisConfig(
        categories: categoriesValue.cast<String>(),
        labelDensity: switch (json['category_label_density']) {
          null || 'auto' => CategoryLabelDensity.auto,
          'show_all' => CategoryLabelDensity.showAll,
          final value => throw FormatException(
            'Unknown category_label_density "$value".',
          ),
        },
        labelOverflow: switch (json['category_label_overflow']) {
          null || 'wrap' => CategoryLabelOverflow.wrap,
          'ellipsis' => CategoryLabelOverflow.ellipsis,
          final value => throw FormatException(
            'Unknown category_label_overflow "$value".',
          ),
        },
        minimumCategoryExtent:
            (json['category_minimum_extent'] as num?)?.toDouble() ?? 56,
        maximumLabelExtent:
            (json['category_maximum_label_extent'] as num?)?.toDouble() ?? 104,
        maxLabelLines: (json['category_max_label_lines'] as num?)?.toInt() ?? 2,
        labelRotationDegrees:
            (json['category_label_rotation'] as num?)?.toDouble() ?? 0,
        autoViewport: json['category_auto_viewport'] as bool? ?? true,
      );
    }

    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      categoryAxis: categoryAxis,
      maxHeight: categoryAxis == null ? 60 : 104,
    );
  }

  static YAxisConfig? _parseYAxisConfig(Map<String, dynamic>? json) {
    if (json == null) return null;

    final positionStr = json['position'] as String?;
    final position = switch (positionStr?.toLowerCase()) {
      'right' => YAxisPosition.right,
      _ => YAxisPosition.left,
    };

    return YAxisConfig(
      position: position,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  static InteractionConfig? _parseInteractionConfig(
    Map<String, dynamic>? json, {
    required bool isPie,
  }) {
    if (json == null && !isPie) return null;

    final showCrosshair = json?['show_crosshair'] as bool? ?? true;
    final showTooltip = json?['show_tooltip'] as bool? ?? true;
    final selectionOperation = switch (json?['selection_operation']) {
      null || 'replace' => ChartSelectionOperation.replace,
      'add' => ChartSelectionOperation.add,
      'subtract' => ChartSelectionOperation.subtract,
      'toggle' => ChartSelectionOperation.toggle,
      final value => throw FormatException(
        'Unknown selection_operation "$value".',
      ),
    };
    final selectionScope = switch (json?['selection_scope']) {
      null || 'mark' => ChartSelectionScope.mark,
      'category' => ChartSelectionScope.category,
      'category_stack' || 'stack' => ChartSelectionScope.categoryStack,
      'whole_series' || 'series' => ChartSelectionScope.wholeSeries,
      'mark_or_whole_series' ||
      'mark_or_series' ||
      'mark_and_whole_series' ||
      'mark_and_series' => ChartSelectionScope.markOrWholeSeries,
      final value => throw FormatException('Unknown selection_scope "$value".'),
    };
    final selectionDragActivation =
        switch (json?['selection_drag_activation']) {
          null ||
          'primary' ||
          'primary_button' => ChartSelectionDragActivation.primaryButton,
          'shift_primary' || 'shift_primary_button' =>
            ChartSelectionDragActivation.shiftPrimaryButton,
          final value => throw FormatException(
            'Unknown selection_drag_activation "$value".',
          ),
        };

    return InteractionConfig(
      enablePan: isPie ? false : (json?['enable_pan'] as bool? ?? true),
      enableZoom: isPie ? false : (json?['enable_zoom'] as bool? ?? true),
      enableSelection: json?['enable_selection'] as bool? ?? true,
      selection: ChartSelectionConfig(
        scope: selectionScope,
        operation: selectionOperation,
        dragActivation: selectionDragActivation,
        clearOnBackgroundTap:
            json?['selection_clear_on_background_tap'] as bool? ?? true,
        useModifierKeys: json?['selection_use_modifier_keys'] as bool? ?? true,
        dataPointHitRadius:
            (json?['selection_data_point_hit_radius'] as num?)?.toDouble() ??
            20,
        completeSeriesHitRadius:
            (json?['selection_complete_series_hit_radius'] as num?)
                ?.toDouble() ??
            22,
        dataPointHoverScale:
            (json?['selection_data_point_hover_scale'] as num?)?.toDouble() ??
            1.5,
        dataPointSelectionScale:
            (json?['selection_data_point_selection_scale'] as num?)
                ?.toDouble() ??
            2.67,
        completeSeriesHoverStrokeScale:
            (json?['selection_complete_series_hover_stroke_scale'] as num?)
                ?.toDouble() ??
            1.75,
        completeSeriesSelectionStrokeScale:
            (json?['selection_complete_series_selection_stroke_scale'] as num?)
                ?.toDouble() ??
            1.5,
      ),
      crosshair: CrosshairConfig(enabled: isPie ? false : showCrosshair),
      tooltip: TooltipConfig(enabled: showTooltip),
    );
  }

  static PieChartStyle _parsePieChartStyle(Map<String, dynamic>? json) {
    const defaults = PieChartStyle();
    return PieChartStyle(
      startAngleDegrees:
          (json?['pie_start_angle'] as num?)?.toDouble() ??
          defaults.startAngleDegrees,
      clockwise: json?['pie_clockwise'] as bool? ?? defaults.clockwise,
      radiusFactor:
          (json?['pie_radius_factor'] as num?)?.toDouble() ??
          defaults.radiusFactor,
      sliceGap:
          (json?['pie_slice_gap'] as num?)?.toDouble() ?? defaults.sliceGap,
      borderWidth:
          (json?['pie_border_width'] as num?)?.toDouble() ??
          defaults.borderWidth,
      borderColor: json?['pie_border_color'] is String
          ? _parseColor(json!['pie_border_color'] as String)
          : null,
      borderColorMode: switch (json?['pie_border_color_mode']) {
        null => null,
        'chart_theme' => PieBorderColorMode.chartTheme,
        'slice' => PieBorderColorMode.slice,
        final value => throw FormatException(
          'Unknown pie_border_color_mode "$value".',
        ),
      },
      borderHueShiftDegrees: (json?['pie_border_hue_shift'] as num?)
          ?.toDouble(),
      borderSaturationShift: (json?['pie_border_saturation_shift'] as num?)
          ?.toDouble(),
      borderLightnessShift: (json?['pie_border_lightness_shift'] as num?)
          ?.toDouble(),
      gradient: _parsePieGradient(json),
      selectionExplodeOffset:
          (json?['pie_selection_explode_offset'] as num?)?.toDouble() ??
          defaults.selectionExplodeOffset,
      opacity: (json?['pie_opacity'] as num?)?.toDouble(),
      cornerRadius: (json?['pie_corner_radius'] as num?)?.toDouble(),
      cornerTreatment: switch (json?['pie_corner_treatment']) {
        null => null,
        'round_all' => PieCornerTreatment.roundAll,
        'outer_only' => PieCornerTreatment.outerOnly,
        'circular_center' => PieCornerTreatment.circularCenter,
        final value => throw FormatException(
          'Unknown pie_corner_treatment "$value".',
        ),
      },
      shadow: _parsePieElevation(json, prefix: 'pie_shadow'),
      selectedElevation: _parsePieElevation(json, prefix: 'pie_selected_glow'),
      animationMode: switch (json?['pie_animation_mode']) {
        null => null,
        'none' => PieAnimationMode.none,
        'grow' => PieAnimationMode.grow,
        'sweep' => PieAnimationMode.sweep,
        'fade' => PieAnimationMode.fade,
        final value => throw FormatException(
          'Unknown pie_animation_mode "$value".',
        ),
      },
    );
  }

  static RadialSelectionStyle _parseRadialSelectionStyle(
    Map<String, dynamic>? json,
  ) {
    const defaults = RadialSelectionStyle();
    return RadialSelectionStyle(
      effect: switch (json?['pie_selection_effect']) {
        null => defaults.effect,
        'explode' => RadialSelectionEffect.explode,
        'lift' => RadialSelectionEffect.lift,
        final value => throw FormatException(
          'Unknown pie_selection_effect "$value".',
        ),
      },
      liftScale:
          (json?['pie_selection_lift_scale'] as num?)?.toDouble() ??
          defaults.liftScale,
      liftOffset:
          (json?['pie_selection_lift_offset'] as num?)?.toDouble() ??
          defaults.liftOffset,
      backdropBlur:
          (json?['pie_selection_backdrop_blur'] as num?)?.toDouble() ??
          defaults.backdropBlur,
    );
  }

  static PieGradientStyle? _parsePieGradient(Map<String, dynamic>? json) {
    if (json == null) return null;
    final typeValue = json['pie_gradient_type'];
    final enabledValue = json['pie_gradient_enabled'];
    final startColorValue = json['pie_gradient_start_color'];
    final endColorValue = json['pie_gradient_end_color'];
    final startShiftValue = json['pie_gradient_start_lightness_shift'];
    final endShiftValue = json['pie_gradient_end_lightness_shift'];
    final angleValue = json['pie_gradient_angle'];
    if (typeValue == null &&
        enabledValue == null &&
        startColorValue == null &&
        endColorValue == null &&
        startShiftValue == null &&
        endShiftValue == null &&
        angleValue == null) {
      return null;
    }

    const defaults = PieGradientStyle();
    return PieGradientStyle(
      enabled: enabledValue as bool? ?? defaults.enabled,
      type: switch (typeValue) {
        null || 'linear' => PieGradientType.linear,
        'radial' => PieGradientType.radial,
        final value => throw FormatException(
          'Unknown pie_gradient_type "$value".',
        ),
      },
      startColor: startColorValue is String
          ? _parseColor(startColorValue)
          : null,
      endColor: endColorValue is String ? _parseColor(endColorValue) : null,
      startLightnessShift:
          (startShiftValue as num?)?.toDouble() ?? defaults.startLightnessShift,
      endLightnessShift:
          (endShiftValue as num?)?.toDouble() ?? defaults.endLightnessShift,
      angleDegrees: (angleValue as num?)?.toDouble() ?? defaults.angleDegrees,
    );
  }

  static PieElevationStyle? _parsePieElevation(
    Map<String, dynamic>? json, {
    required String prefix,
  }) {
    if (json == null) return null;
    final colorValue = json['${prefix}_color'];
    final blurValue = json['${prefix}_blur'];
    final spreadValue = json['${prefix}_spread'];
    final offsetXValue = json['${prefix}_offset_x'];
    final offsetYValue = json['${prefix}_offset_y'];
    final opacityValue = json['${prefix}_opacity'];
    if (colorValue == null &&
        blurValue == null &&
        spreadValue == null &&
        offsetXValue == null &&
        offsetYValue == null &&
        opacityValue == null) {
      return null;
    }
    return PieElevationStyle(
      color: colorValue is String ? _parseColor(colorValue) : null,
      blurRadius: (blurValue as num?)?.toDouble() ?? 0,
      spreadRadius: (spreadValue as num?)?.toDouble() ?? 0,
      offset: Offset(
        (offsetXValue as num?)?.toDouble() ?? 0,
        (offsetYValue as num?)?.toDouble() ?? 0,
      ),
      opacity:
          (opacityValue as num?)?.toDouble() ??
          (prefix == 'pie_selected_glow' ? 0.45 : 0.65),
    );
  }

  static PieDataLabelConfig _parsePieDataLabels(Map<String, dynamic>? json) {
    const defaults = PieDataLabelConfig();
    final position = switch (json?['pie_label_position']) {
      'inside' => PieDataLabelPosition.inside,
      'outside' || null => PieDataLabelPosition.outside,
      final value => throw FormatException(
        'Unknown pie_label_position "$value".',
      ),
    };
    final secondaryContent = switch (json?['pie_secondary_label_content']) {
      null => null,
      'category' => PieDataLabelContent.category,
      'value' => PieDataLabelContent.value,
      'percentage' => PieDataLabelContent.percentage,
      'category_and_value' => PieDataLabelContent.categoryAndValue,
      'category_and_percentage' => PieDataLabelContent.categoryAndPercentage,
      'value_and_percentage' => PieDataLabelContent.valueAndPercentage,
      'category_value_and_percentage' =>
        PieDataLabelContent.categoryValueAndPercentage,
      final value => throw FormatException(
        'Unknown pie_secondary_label_content "$value".',
      ),
    };
    return PieDataLabelConfig(
      isVisible: json?['show_data_labels'] as bool? ?? defaults.isVisible,
      position: position,
      content: switch (json?['pie_label_content']) {
        'category' => PieDataLabelContent.category,
        'value' => PieDataLabelContent.value,
        'percentage' => PieDataLabelContent.percentage,
        'category_and_value' => PieDataLabelContent.categoryAndValue,
        'category_and_percentage' ||
        null => PieDataLabelContent.categoryAndPercentage,
        'value_and_percentage' => PieDataLabelContent.valueAndPercentage,
        'category_value_and_percentage' =>
          PieDataLabelContent.categoryValueAndPercentage,
        final value => throw FormatException(
          'Unknown pie_label_content "$value".',
        ),
      },
      secondaryContent: secondaryContent,
      secondaryPosition: switch (json?['pie_secondary_label_position']) {
        'inside' => PieDataLabelPosition.inside,
        'outside' => PieDataLabelPosition.outside,
        null =>
          position == PieDataLabelPosition.inside
              ? PieDataLabelPosition.outside
              : PieDataLabelPosition.inside,
        final value => throw FormatException(
          'Unknown pie_secondary_label_position "$value".',
        ),
      },
      minimumShare:
          (json?['pie_label_minimum_share'] as num?)?.toDouble() ??
          defaults.minimumShare,
      minimumSweepDegrees:
          (json?['pie_label_minimum_sweep'] as num?)?.toDouble() ??
          defaults.minimumSweepDegrees,
      insideOffset:
          (json?['pie_inside_label_offset'] as num?)?.toDouble() ??
          defaults.insideOffset,
      outsideOffset:
          (json?['pie_label_offset'] as num?)?.toDouble() ??
          defaults.outsideOffset,
    );
  }

  static GridConfig? _parseGridConfig(Map<String, dynamic>? json) {
    if (json == null) return null;

    final showGrid = json['show_grid'] as bool? ?? true;
    if (!showGrid) {
      return const GridConfig(horizontal: false, vertical: false);
    }
    return null; // Use defaults
  }

  static bool _parseShowLegend(Map<String, dynamic>? json) {
    if (json == null) return true;
    return json['show_legend'] as bool? ?? true;
  }

  static Color? _parseColor(String colorStr) {
    // Handle hex colors
    if (colorStr.startsWith('#')) {
      final hex = colorStr.substring(1);
      if (hex.length == 6) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          return Color(0xFF000000 | value);
        }
      } else if (hex.length == 8) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          return Color(value);
        }
      }
    }

    // Handle named colors
    return _namedColors[colorStr.toLowerCase()];
  }

  static const Map<String, Color> _namedColors = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'yellow': Colors.yellow,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'amber': Colors.amber,
    'indigo': Colors.indigo,
    'lime': Colors.lime,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'black': Colors.black,
    'white': Colors.white,
  };
}
