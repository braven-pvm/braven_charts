import 'axis_config.dart';
import 'series_config.dart';

/// Chart type enumeration
enum ChartType {
  line,
  area,
  bar,
  scatter,
}

/// Style configuration for charts.
///
/// Contains visual styling properties like colors, fonts, and layout.
class ChartStyleConfig {
  /// Background color of the chart
  final dynamic backgroundColor;

  /// Color for grid lines
  final dynamic gridColor;

  /// Color for axes
  final dynamic axisColor;

  /// Plot area configuration
  final dynamic plotArea;

  /// Font family for text
  final String? fontFamily;

  /// Font size for text
  final double? fontSize;

  /// Creates a new ChartStyleConfig instance
  ChartStyleConfig({
    this.backgroundColor,
    this.gridColor,
    this.axisColor,
    this.plotArea,
    this.fontFamily,
    this.fontSize,
  });

  /// Creates a ChartStyleConfig from JSON
  factory ChartStyleConfig.fromJson(Map<String, dynamic> json) {
    return ChartStyleConfig(
      backgroundColor: json['backgroundColor'],
      gridColor: json['gridColor'],
      axisColor: json['axisColor'],
      plotArea: json['plotArea'],
      fontFamily: json['fontFamily'] as String?,
      fontSize: json['fontSize'] as double?,
    );
  }

  /// Converts ChartStyleConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (gridColor != null) 'gridColor': gridColor,
      if (axisColor != null) 'axisColor': axisColor,
      if (plotArea != null) 'plotArea': plotArea,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontSize != null) 'fontSize': fontSize,
    };
  }
}

/// Complete chart configuration for rendering.
///
/// Must have at least one series and at most 4 Y-axes.
class ChartConfiguration {
  /// Unique identifier for the chart
  final String? id;

  /// Type of chart (line, area, bar, scatter)
  final ChartType type;

  /// Optional chart title
  final String? title;

  /// Optional chart subtitle
  final String? subtitle;

  /// Series configurations (must have at least one)
  final List<SeriesConfig> series;

  /// X-axis configuration
  final XAxisConfig? xAxis;

  /// Y-axis configurations (maximum 4)
  final List<YAxisConfig> yAxes;

  /// Style configuration
  final ChartStyleConfig? style;

  /// Interaction configuration
  final dynamic interactions;

  /// Annotation configurations
  final List<dynamic>? annotations;

  /// Layout configuration
  final dynamic layout;

  /// Legend configuration
  final dynamic legend;

  /// Grid configuration
  final dynamic grid;

  /// Theme name
  final String? theme;

  // === Config Panel Properties ===

  /// Whether to show grid lines (config panel)
  final bool? showGrid;

  /// Whether to show the legend (config panel)
  final bool? showLegend;

  /// Legend position (config panel)
  final String? legendPosition;

  /// Whether to use dark theme (config panel)
  final bool? useDarkTheme;

  /// Whether to show scrollbar (config panel)
  final bool? showScrollbar;

  /// Creates a new ChartConfiguration instance
  ChartConfiguration({
    this.id,
    required this.type,
    this.title,
    this.subtitle,
    List<SeriesConfig>? series,
    this.xAxis,
    List<YAxisConfig>? yAxes,
    this.style,
    this.interactions,
    this.annotations,
    this.layout,
    this.legend,
    this.grid,
    this.theme,
    this.showGrid,
    this.showLegend,
    this.legendPosition,
    this.useDarkTheme,
    this.showScrollbar,
  })  : series = series ?? [],
        yAxes = yAxes ?? [],
        assert(
          (series ?? []).isNotEmpty,
          'ChartConfiguration must have at least one series',
        ),
        assert(
          (yAxes ?? []).length <= 4,
          'ChartConfiguration can have at most 4 Y-axes',
        );

  /// Creates a ChartConfiguration from JSON
  factory ChartConfiguration.fromJson(Map<String, dynamic> json) {
    return ChartConfiguration(
      id: json['id'] as String?,
      type: ChartType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      series: (json['series'] as List)
          .map((e) => SeriesConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      xAxis: json['xAxis'] != null
          ? XAxisConfig.fromJson(json['xAxis'] as Map<String, dynamic>)
          : null,
      yAxes: (json['yAxes'] as List)
          .map((e) => YAxisConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      style: json['style'] != null
          ? ChartStyleConfig.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      interactions: json['interactions'],
      annotations: json['annotations'] as List<dynamic>?,
      layout: json['layout'],
      legend: json['legend'],
      grid: json['grid'],
      theme: json['theme'] as String?,
      showGrid: json['showGrid'] as bool?,
      showLegend: json['showLegend'] as bool?,
      legendPosition: json['legendPosition'] as String?,
      useDarkTheme: json['useDarkTheme'] as bool?,
      showScrollbar: json['showScrollbar'] as bool?,
    );
  }

  /// Converts ChartConfiguration to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      'series': series.map((s) => s.toJson()).toList(),
      if (xAxis != null) 'xAxis': xAxis!.toJson(),
      'yAxes': yAxes.map((y) => y.toJson()).toList(),
      if (style != null) 'style': style!.toJson(),
      if (interactions != null) 'interactions': interactions,
      if (annotations != null) 'annotations': annotations,
      if (layout != null) 'layout': layout,
      if (legend != null) 'legend': legend,
      if (grid != null) 'grid': grid,
      if (theme != null) 'theme': theme,
      if (showGrid != null) 'showGrid': showGrid,
      if (showLegend != null) 'showLegend': showLegend,
      if (legendPosition != null) 'legendPosition': legendPosition,
      if (useDarkTheme != null) 'useDarkTheme': useDarkTheme,
      if (showScrollbar != null) 'showScrollbar': showScrollbar,
    };
  }

  /// Creates a copy with modified values
  ChartConfiguration copyWith({
    String? id,
    ChartType? type,
    String? title,
    String? subtitle,
    List<SeriesConfig>? series,
    XAxisConfig? xAxis,
    List<YAxisConfig>? yAxes,
    ChartStyleConfig? style,
    dynamic interactions,
    List<dynamic>? annotations,
    dynamic layout,
    dynamic legend,
    dynamic grid,
    String? theme,
    bool? showGrid,
    bool? showLegend,
    String? legendPosition,
    bool? useDarkTheme,
    bool? showScrollbar,
  }) {
    return ChartConfiguration(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      series: series ?? this.series,
      xAxis: xAxis ?? this.xAxis,
      yAxes: yAxes ?? this.yAxes,
      style: style ?? this.style,
      interactions: interactions ?? this.interactions,
      annotations: annotations ?? this.annotations,
      layout: layout ?? this.layout,
      legend: legend ?? this.legend,
      grid: grid ?? this.grid,
      theme: theme ?? this.theme,
      showGrid: showGrid ?? this.showGrid,
      showLegend: showLegend ?? this.showLegend,
      legendPosition: legendPosition ?? this.legendPosition,
      useDarkTheme: useDarkTheme ?? this.useDarkTheme,
      showScrollbar: showScrollbar ?? this.showScrollbar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChartConfiguration) return false;
    return other.id == id &&
        other.type == type &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.theme == theme &&
        other.grid == grid &&
        other.legend == legend &&
        other.interactions == interactions;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      subtitle,
      theme,
      grid,
      legend,
      interactions,
    );
  }

  @override
  String toString() {
    return 'ChartConfiguration(type: ${type.name}, title: $title, series: ${series.length} series)';
  }
}
