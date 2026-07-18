// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_type.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/radial_category_series.dart';
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
      final radiusValue = pointJson['radius'];
      if (radiusValue != null && radiusValue is! num) {
        throw const FormatException(
          'Pie radius values must be numeric when supplied.',
        );
      }
      return ChartDataPoint(
        x: x.toDouble(),
        y: y.toDouble(),
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
    };
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
      'pie' => SeriesStyle.pie,
      'donut' => SeriesStyle.donut,
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
