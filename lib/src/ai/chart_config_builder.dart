// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_type.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
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

    final isPie = chartType == ChartType.pie;
    if (isPie) {
      if (series.length != 1 || series.single is! PieChartSeries) {
        throw const FormatException(
          'Pie charts require exactly one pie series and cannot mix series types.',
        );
      }
      if (json.containsKey('x_axis') || json.containsKey('y_axis')) {
        throw const FormatException(
          'Pie charts do not use x_axis or y_axis configuration.',
        );
      }
    } else if (series.any((value) => value is PieChartSeries)) {
      throw const FormatException(
        'Pie series require chart_type "pie" and cannot mix with Cartesian series.',
      );
    }

    // Parse axes
    final xAxisConfig = isPie
        ? null
        : _parseXAxisConfig(json['x_axis'] as Map<String, dynamic>?);
    final yAxisConfig = isPie
        ? null
        : _parseYAxisConfig(json['y_axis'] as Map<String, dynamic>?);

    // Check for multi-axis mode (series have different units)
    final units = series
        .map((s) => s.unit)
        .where((u) => u != null && u.isNotEmpty)
        .toSet();

    List<YAxisConfig>? yAxes;
    if (!isPie && units.length > 1) {
      // Multi-axis mode: create Y-axes from series configurations
      yAxes = series
          .where((s) => s.yAxisConfig != null)
          .map((s) => s.yAxisConfig!)
          .toList();
    }

    // Parse interactions
    final interactionConfig = _parseInteractionConfig(
      json['interactions'] as Map<String, dynamic>?,
      isPie: isPie,
    );

    // Parse style
    final gridConfig = isPie
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

    final points = dataList.map((d) {
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
      return ChartDataPoint(
        x: x.toDouble(),
        y: y.toDouble(),
        label: pointJson['label'] as String?,
        timestamp: pointJson['timestamp'] != null
            ? DateTime.tryParse(pointJson['timestamp'] as String)
            : null,
        pointStyle: pointColor == null ? null : PointStyle.color(pointColor),
      );
    }).toList();

    // Parse style from series or use parent chart_type style
    final styleStr = json['style'] as String?;
    final style = styleStr != null
        ? _parseSeriesStyle(styleStr)
        : (defaultStyle ?? SeriesStyle.line);

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
        interpolation: LineInterpolation.linear,
        strokeWidth: 2.0,
      ),
      SeriesStyle.area => AreaChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        interpolation: LineInterpolation.linear,
        fillOpacity: 0.3,
      ),
      SeriesStyle.bar => BarChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        barWidthPercent: 0.8,
      ),
      SeriesStyle.scatter => ScatterChartSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        yAxisConfig: yAxisConfig,
        markerRadius: 5.0,
      ),
      SeriesStyle.pie => _buildPieSeries(
        id: id,
        name: name ?? id,
        points: points,
        color: color,
        unit: unit,
        chartStyle: chartStyle,
      ),
    };
  }

  static PieChartSeries _buildPieSeries({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color? color,
    required String? unit,
    required Map<String, dynamic>? chartStyle,
  }) {
    try {
      return PieChartSeries(
        id: id,
        name: name,
        points: points,
        color: color,
        unit: unit,
        pieStyle: _parsePieChartStyle(chartStyle),
        dataLabels: _parsePieDataLabels(chartStyle),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid pie series "$id": ${error.message}');
    }
  }

  static ChartType? _parseChartType(String? type) {
    return switch (type?.toLowerCase()) {
      'line' => ChartType.line,
      'area' => ChartType.area,
      'bar' => ChartType.bar,
      'scatter' => ChartType.scatter,
      'pie' => ChartType.pie,
      _ => null,
    };
  }

  static SeriesStyle? _chartTypeToSeriesStyle(String? type) {
    return switch (type?.toLowerCase()) {
      'line' => SeriesStyle.line,
      'area' => SeriesStyle.area,
      'bar' => SeriesStyle.bar,
      'scatter' => SeriesStyle.scatter,
      'pie' => SeriesStyle.pie,
      _ => SeriesStyle.line, // Default to line
    };
  }

  static SeriesStyle? _parseSeriesStyle(String? style) {
    return switch (style?.toLowerCase()) {
      'line' => SeriesStyle.line,
      'area' => SeriesStyle.area,
      'bar' => SeriesStyle.bar,
      'scatter' => SeriesStyle.scatter,
      'pie' => SeriesStyle.pie,
      _ => null,
    };
  }

  static XAxisConfig? _parseXAxisConfig(Map<String, dynamic>? json) {
    if (json == null) return null;

    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
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

    return InteractionConfig(
      enablePan: isPie ? false : (json?['enable_pan'] as bool? ?? true),
      enableZoom: isPie ? false : (json?['enable_zoom'] as bool? ?? true),
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
      selectionExplodeOffset:
          (json?['pie_selection_explode_offset'] as num?)?.toDouble() ??
          defaults.selectionExplodeOffset,
    );
  }

  static PieDataLabelConfig _parsePieDataLabels(Map<String, dynamic>? json) {
    const defaults = PieDataLabelConfig();
    return PieDataLabelConfig(
      isVisible: json?['show_data_labels'] as bool? ?? defaults.isVisible,
      position: switch (json?['pie_label_position']) {
        'inside' => PieDataLabelPosition.inside,
        'outside' || null => PieDataLabelPosition.outside,
        final value => throw FormatException(
          'Unknown pie_label_position "$value".',
        ),
      },
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
      minimumShare:
          (json?['pie_label_minimum_share'] as num?)?.toDouble() ??
          defaults.minimumShare,
      minimumSweepDegrees:
          (json?['pie_label_minimum_sweep'] as num?)?.toDouble() ??
          defaults.minimumSweepDegrees,
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
