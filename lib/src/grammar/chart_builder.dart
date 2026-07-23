// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/painting.dart' show Color;
import 'package:flutter/widgets.dart' show Key;

import '../controllers/chart_interaction_group_controller.dart';
import '../models/bar_chart_style.dart' show BarLabelStyle, BarLayoutMode;
import '../models/braven_chart_controller.dart';
import '../models/chart_annotation.dart' show AnnotationAxis, TrendType;
import '../models/chart_series.dart' show LineInterpolation;
import '../models/data_point_label_config.dart' show DataPointLabelConfig;
import '../models/enums.dart' show MarkerShape;
import '../models/chart_state_config.dart' show ChartEmptyStateConfig;
import '../models/chart_theme.dart' show ChartTheme;
import '../models/donut_chart_config.dart'
    show DonutCenterContent, DonutChartStyle;
import '../models/grid_config.dart' show GridConfig;
import '../models/interaction_config.dart' show InteractionConfig;
import '../models/pie_chart_config.dart' show PieChartStyle, PieDataLabelConfig;
import '../models/scatter_marker_style.dart'
    show
        ScatterCategoryStyle,
        ScatterColorEncoding,
        ScatterMarkerStyle,
        ScatterOpacityEncoding,
        ScatterSizeEncoding;
import '../models/x_axis_config.dart' show XAxisConfig;
import '../models/y_axis_config.dart' show YAxisConfig;
import '../models/y_axis_position.dart' show YAxisPosition;
import '../theming/components/series_theme.dart' show SeriesMarkerShape;
import 'braven_facet_plot.dart';
import 'braven_plot.dart';
import 'channel.dart';
import 'facet_spec.dart';
import 'grammar_diagnostics.dart';
import 'mark.dart';
import 'plot_spec.dart';

/// The chained, grammar-of-graphics way to author a chart.
///
/// ```dart
/// BravenChart.of(rides)
///     .x((r) => r.km, label: 'Distance')
///     .y((r) => r.power)
///     .geomLine(name: 'Power')
///     .trend(method: TrendType.movingAverage, windowSize: 30)
///     .build()
/// ```
///
/// ## What this class is and is not
///
/// It is a [PlotSpec] BUILDER and nothing else. It holds no rendering, no
/// lowering and no defaults of the render pipeline's — `toSpec()` hands back
/// the same spec a user could have typed by hand, and `build()` wraps it in a
/// [BravenPlot]. That is why there is exactly one description of what every
/// verb means, and why the lowering parity suite covers this facade for free.
///
/// ## Immutable
///
/// Every verb returns a NEW builder; the receiver is untouched. A chain can
/// therefore be branched — a shared base with two different geometries on top —
/// and a builder held in a field cannot be mutated by a caller who chains off
/// it.
///
/// ## Fail-fast
///
/// A `geom*` call with no accessor to use — neither an explicit one nor a chain
/// default set by [x]/[y] — throws [GrammarSpecException] with
/// [GrammarDiagnosticCode.missingEncoding] AT THAT CALL, naming the verb and
/// the channel. A [trend] with nothing to fit throws
/// [GrammarDiagnosticCode.unknownTrendSource] at its call. Neither waits for
/// `build()`, so the stack trace points at the line that is wrong.
///
/// ## Mark ids
///
/// Each geometry is given an explicit id as it is appended: the one passed to
/// the verb, or `mark-<index>` using its position in the chain. That is what
/// lets [trend] default its source to the geometry immediately before it, and
/// it matches the id the lowering would have assigned anyway.
final class BravenChart<T> {
  const BravenChart._({
    required List<T> rows,
    required List<Mark<T>> marks,
    required List<YAxisConfig> yAxes,
    FieldAccessor<T, num>? defaultX,
    FieldAccessor<T, num>? defaultY,
    String? xLabel,
    String? yLabel,
    bool transposed = false,
    ChartTheme? theme,
    InteractionConfig? interaction,
    XAxisConfig? xAxis,
    GridConfig? grid,
    String? title,
    String? subtitle,
    bool? showLegend,
    FacetSpec<T>? facet,
  }) : _rows = rows,
       _marks = marks,
       _yAxes = yAxes,
       _defaultX = defaultX,
       _defaultY = defaultY,
       _xLabel = xLabel,
       _yLabel = yLabel,
       _transposed = transposed,
       _theme = theme,
       _interaction = interaction,
       _xAxis = xAxis,
       _grid = grid,
       _title = title,
       _subtitle = subtitle,
       _showLegend = showLegend,
       _facet = facet;

  /// Starts a chain over [rows].
  static BravenChart<T> of<T>(List<T> rows) => BravenChart<T>._(
    rows: rows,
    marks: const [],
    yAxes: const <YAxisConfig>[],
  );

  final List<T> _rows;
  final List<Mark<T>> _marks;
  final List<YAxisConfig> _yAxes;
  final FieldAccessor<T, num>? _defaultX;
  final FieldAccessor<T, num>? _defaultY;
  final String? _xLabel;
  final String? _yLabel;
  final bool _transposed;
  final ChartTheme? _theme;
  final InteractionConfig? _interaction;
  final XAxisConfig? _xAxis;
  final GridConfig? _grid;
  final String? _title;
  final String? _subtitle;
  final bool? _showLegend;
  final FacetSpec<T>? _facet;

  BravenChart<T> _copy({
    List<Mark<T>>? marks,
    List<YAxisConfig>? yAxes,
    FieldAccessor<T, num>? defaultX,
    FieldAccessor<T, num>? defaultY,
    String? xLabel,
    String? yLabel,
    bool? transposed,
    ChartTheme? theme,
    InteractionConfig? interaction,
    XAxisConfig? xAxis,
    GridConfig? grid,
    String? title,
    String? subtitle,
    bool? showLegend,
    FacetSpec<T>? facet,
  }) => BravenChart<T>._(
    rows: _rows,
    marks: marks ?? _marks,
    yAxes: yAxes ?? _yAxes,
    defaultX: defaultX ?? _defaultX,
    defaultY: defaultY ?? _defaultY,
    xLabel: xLabel ?? _xLabel,
    yLabel: yLabel ?? _yLabel,
    transposed: transposed ?? _transposed,
    theme: theme ?? _theme,
    interaction: interaction ?? _interaction,
    xAxis: xAxis ?? _xAxis,
    grid: grid ?? _grid,
    title: title ?? _title,
    subtitle: subtitle ?? _subtitle,
    showLegend: showLegend ?? _showLegend,
    facet: facet ?? _facet,
  );

  BravenChart<T> _append(Mark<T> mark) =>
      _copy(marks: <Mark<T>>[..._marks, mark]);

  String _idFor(String? id) => id ?? 'mark-${_marks.length}';

  Iterable<String> get _geometryIds => _marks
      .where(
        (mark) =>
            mark is LineMark<T> ||
            mark is AreaMark<T> ||
            mark is BarMark<T> ||
            mark is ScatterMark<T> ||
            mark is CandlestickMark<T>,
      )
      .map((mark) => mark.id!);

  FieldAccessor<T, num> _resolveX(String verb, FieldAccessor<T, num>? x) =>
      x ?? _defaultX ?? (throw GrammarSpecException.missingEncoding(verb, 'x'));

  FieldAccessor<T, num> _resolveY(String verb, FieldAccessor<T, num>? y) =>
      y ?? _defaultY ?? (throw GrammarSpecException.missingEncoding(verb, 'y'));

  /// Sets the horizontal accessor every later geometry inherits.
  ///
  /// [label] names the X axis, unless [xAxis] configures one explicitly —
  /// explicit configuration always wins.
  BravenChart<T> x(FieldAccessor<T, num> accessor, {String? label}) =>
      _copy(defaultX: accessor, xLabel: label);

  /// Sets the vertical accessor every later geometry inherits.
  ///
  /// [label] names the default Y axis, unless [yAxis] declares axes
  /// explicitly — explicit configuration always wins.
  BravenChart<T> y(FieldAccessor<T, num> accessor, {String? label}) =>
      _copy(defaultY: accessor, yLabel: label);

  /// Appends a connected line through `(x, y)`.
  BravenChart<T> geomLine({
    FieldAccessor<T, num>? x,
    FieldAccessor<T, num>? y,
    String? id,
    String? name,
    Color? color,
    double? strokeWidth,
    List<double>? dashPattern,
    LineInterpolation? interpolation,
    bool? showDataPointMarkers,
    DataPointLabelConfig? dataPointLabels,
    String? yAxisId,
  }) => _append(
    LineMark<T>(
      id: _idFor(id),
      x: _resolveX('geomLine', x),
      y: _resolveY('geomLine', y),
      name: name,
      color: color,
      strokeWidth: strokeWidth,
      dashPattern: dashPattern,
      interpolation: interpolation,
      showDataPointMarkers: showDataPointMarkers,
      dataPointLabels: dataPointLabels,
      yAxisId: yAxisId,
    ),
  );

  /// Appends a filled band between `y` and a baseline.
  BravenChart<T> geomArea({
    FieldAccessor<T, num>? x,
    FieldAccessor<T, num>? y,
    String? id,
    String? name,
    Color? color,
    double? baseline,
    double? fillOpacity,
    double? strokeWidth,
    List<double>? dashPattern,
    LineInterpolation? interpolation,
    bool? showDataPointMarkers,
    DataPointLabelConfig? dataPointLabels,
    String? yAxisId,
  }) => _append(
    AreaMark<T>(
      id: _idFor(id),
      x: _resolveX('geomArea', x),
      y: _resolveY('geomArea', y),
      name: name,
      color: color,
      baseline: baseline,
      fillOpacity: fillOpacity,
      strokeWidth: strokeWidth,
      dashPattern: dashPattern,
      interpolation: interpolation,
      showDataPointMarkers: showDataPointMarkers,
      dataPointLabels: dataPointLabels,
      yAxisId: yAxisId,
    ),
  );

  /// Appends one bar per row.
  ///
  /// Bars have no orientation of their own: transposing the plane is a
  /// whole-chart operation, expressed by [transposed].
  BravenChart<T> geomBar({
    FieldAccessor<T, num>? x,
    FieldAccessor<T, num>? y,
    String? id,
    String? name,
    Color? color,
    double? barWidthPercent,
    double? barWidthPixels,
    double? barGap,
    BarLayoutMode? layoutMode,
    String? groupId,
    double? baselineValue,
    BarLabelStyle? labelStyle,
    String? yAxisId,
  }) => _append(
    BarMark<T>(
      id: _idFor(id),
      x: _resolveX('geomBar', x),
      y: _resolveY('geomBar', y),
      name: name,
      color: color,
      barWidthPercent: barWidthPercent,
      barWidthPixels: barWidthPixels,
      barGap: barGap,
      layoutMode: layoutMode,
      groupId: groupId,
      baselineValue: baselineValue,
      labelStyle: labelStyle,
      yAxisId: yAxisId,
    ),
  );

  /// Appends one marker per row — the only geometry with scale-driven channels.
  ///
  /// [colorBy] requires [colorEncoding] and [categoryBy] requires a non-empty
  /// [categories]; the package ships neither a default color ramp nor a
  /// categorical palette, so a channel without its template is rejected when
  /// the spec is lowered.
  BravenChart<T> geomPoint({
    FieldAccessor<T, num>? x,
    FieldAccessor<T, num>? y,
    String? id,
    String? name,
    Color? color,
    Channel<T>? size,
    ScatterSizeEncoding? sizeEncoding,
    Channel<T>? colorBy,
    ScatterColorEncoding? colorEncoding,
    Channel<T>? opacityBy,
    ScatterOpacityEncoding? opacityEncoding,
    CategoryChannel<T>? categoryBy,
    List<ScatterCategoryStyle> categories = const <ScatterCategoryStyle>[],
    double? markerRadius,
    SeriesMarkerShape? markerShape,
    ScatterMarkerStyle? markerStyle,
    String? yAxisId,
  }) => _append(
    ScatterMark<T>(
      id: _idFor(id),
      x: _resolveX('geomPoint', x),
      y: _resolveY('geomPoint', y),
      name: name,
      color: color,
      size: size,
      sizeEncoding: sizeEncoding,
      colorBy: colorBy,
      colorEncoding: colorEncoding,
      opacityBy: opacityBy,
      opacityEncoding: opacityEncoding,
      categoryBy: categoryBy,
      categories: categories,
      markerRadius: markerRadius,
      markerShape: markerShape,
      markerStyle: markerStyle,
      yAxisId: yAxisId,
    ),
  );

  /// Appends one open-high-low-close candle per row.
  BravenChart<T> geomCandlestick({
    required FieldAccessor<T, num> open,
    required FieldAccessor<T, num> high,
    required FieldAccessor<T, num> low,
    required FieldAccessor<T, num> close,
    FieldAccessor<T, num>? x,
    FieldAccessor<T, DateTime>? timestamp,
    String? id,
    String? name,
    Color? color,
    String? yAxisId,
  }) => _append(
    CandlestickMark<T>(
      id: _idFor(id),
      x: _resolveX('geomCandlestick', x),
      open: open,
      high: high,
      low: low,
      close: close,
      timestamp: timestamp,
      name: name,
      color: color,
      yAxisId: yAxisId,
    ),
  );

  /// Appends a pie: each row is a slice, [value] is the angle-share.
  ///
  /// A pie makes the spec RADIAL — it may contain no other mark, and honors no
  /// Cartesian axis/grid option. [radius] encodes an optional second metric as
  /// a variable slice radius. Rich styling is deferred to [style]/[dataLabels],
  /// the real config objects, exactly as the Cartesian geoms defer to config.
  BravenChart<T> geomPie({
    required FieldAccessor<T, Object?> category,
    required FieldAccessor<T, num> value,
    FieldAccessor<T, num>? radius,
    String? id,
    String? name,
    Color? color,
    PieChartStyle? style,
    PieDataLabelConfig? dataLabels,
  }) => _append(
    PieMark<T>(
      id: _idFor(id),
      category: category,
      value: value,
      radius: radius,
      name: name,
      color: color,
      style: style,
      dataLabels: dataLabels,
    ),
  );

  /// Appends a donut. With [ring] set, rows partition into concentric donuts
  /// (one per distinct ring value, first-seen order); without it, a single
  /// donut. [value] is the angle-share; [radius] is an optional variable
  /// radius. Rich styling is deferred to [style]/[center]/[dataLabels].
  BravenChart<T> geomDonut({
    required FieldAccessor<T, Object?> category,
    required FieldAccessor<T, num> value,
    FieldAccessor<T, num>? radius,
    FieldAccessor<T, Object?>? ring,
    String? id,
    String? name,
    Color? color,
    DonutChartStyle? style,
    DonutCenterContent? center,
    PieDataLabelConfig? dataLabels,
  }) => _append(
    DonutMark<T>(
      id: _idFor(id),
      category: category,
      value: value,
      radius: radius,
      ring: ring,
      name: name,
      color: color,
      style: style,
      center: center,
      dataLabels: dataLabels,
    ),
  );

  /// Fits a statistic over a geometry already in the chain.
  ///
  /// [of] names the geometry's mark id; leaving it null uses the geometry
  /// appended immediately before this call. A trend cannot be fitted over
  /// another trend.
  BravenChart<T> trend({
    String? of,
    TrendType method = TrendType.linear,
    int? windowSize,
    String? id,
    String? name,
    Color? color,
    bool showConfidenceBand = false,
    double? lineWidth,
    List<double>? dashPattern,
  }) {
    final geometries = _geometryIds.toList();
    final source = of ?? (geometries.isEmpty ? null : geometries.last);
    if (source == null || !geometries.contains(source)) {
      throw GrammarSpecException.unknownTrendSource(source ?? '', geometries);
    }
    return _append(
      TrendMark<T>(
        id: _idFor(id),
        sourceMarkId: source,
        trendType: method,
        windowSize: windowSize,
        name: name,
        color: color,
        showConfidenceBand: showConfidenceBand,
        lineWidth: lineWidth,
        dashPattern: dashPattern,
      ),
    );
  }

  /// Appends a reference line at [value] on [axis].
  ///
  /// A threshold produces no geometry: it lowers to a `ThresholdAnnotation`.
  /// It binds no Y axis — the line is drawn in axis-value space — so there is
  /// no `yAxisId` here.
  BravenChart<T> threshold({
    required double value,
    AnnotationAxis axis = AnnotationAxis.y,
    String? id,
    String? label,
    Color? color,
    double? strokeWidth,
    List<double>? dashPattern,
  }) => _append(
    ThresholdMark<T>(
      id: _idFor(id),
      value: value,
      axis: axis,
      label: label,
      color: color,
      strokeWidth: strokeWidth,
      dashPattern: dashPattern,
    ),
  );

  /// Appends a shaded band from [start] to [end] on [axis].
  ///
  /// A band produces no geometry: it lowers to a 1-D `RangeAnnotation` (an X
  /// band or a Y band, never a 2-D box). [color] is the fill.
  BravenChart<T> band({
    required double start,
    required double end,
    AnnotationAxis axis = AnnotationAxis.y,
    String? id,
    String? label,
    Color? color,
  }) => _append(
    BandMark<T>(
      id: _idFor(id),
      start: start,
      end: end,
      axis: axis,
      label: label,
      color: color,
    ),
  );

  /// Appends a marker on point [dataPointIndex] of the series [seriesId].
  ///
  /// This annotates ONE point of a geometry already in the chain (it lowers to
  /// a `PointAnnotation`), and is not the scatter geometry. [seriesId] names
  /// the geometry's mark id, and [dataPointIndex] its row index.
  BravenChart<T> pointAt({
    required String seriesId,
    required int dataPointIndex,
    String? id,
    String? label,
    Color? color,
    double? markerSize,
    MarkerShape? markerShape,
  }) => _append(
    PointMark<T>(
      id: _idFor(id),
      seriesId: seriesId,
      dataPointIndex: dataPointIndex,
      label: label,
      color: color,
      markerSize: markerSize,
      markerShape: markerShape,
    ),
  );

  /// Transposes the Cartesian plane. Legal on an all-bar chain only.
  BravenChart<T> transposed() => _copy(transposed: true);

  /// Sets the theme handed to the chart unchanged.
  BravenChart<T> theme(ChartTheme theme) => _copy(theme: theme);

  /// Sets the interaction configuration.
  BravenChart<T> interaction(InteractionConfig config) =>
      _copy(interaction: config);

  /// Configures the X axis. Wins over the label passed to [x].
  BravenChart<T> xAxis(XAxisConfig config) => _copy(xAxis: config);

  /// Declares one Y-axis slot. Repeatable; declaration order is axis order.
  ///
  /// Marks bind to a slot through the `yAxisId` parameter of their geom verb.
  BravenChart<T> yAxis(YAxisConfig config) =>
      _copy(yAxes: <YAxisConfig>[..._yAxes, config]);

  /// Sets the chart's grid configuration, forwarded to the chart unchanged.
  BravenChart<T> grid(GridConfig grid) => _copy(grid: grid);

  /// Sets the chart [title], and optionally a [subtitle] beneath it.
  BravenChart<T> title(String title, {String? subtitle}) =>
      _copy(title: title, subtitle: subtitle);

  /// Shows or hides the chart legend.
  BravenChart<T> legend(bool show) => _copy(showLegend: show);

  /// Renders this chain as N synchronized small-multiple panels — one per
  /// distinct value of [by], in first-seen (data) order.
  ///
  /// [columns] fixes the grid width (null lays it out at `ceil(sqrt(N))`);
  /// [scales] controls axis sharing across panels ([FacetScales.fixed] shares
  /// both); [label] prefixes each panel's strip label. Faceting is set as an
  /// optional field on the [PlotSpec], so the spec stays the single complete
  /// description. Terminate the chain with [buildFaceted]; a faceted chain
  /// rejects the single-panel [build].
  BravenChart<T> facet(
    FieldAccessor<T, Object?> by, {
    int? columns,
    FacetScales scales = FacetScales.fixed,
    String? label,
  }) => _copy(
    facet: FacetSpec<T>(
      by: by,
      columns: columns,
      scales: scales,
      label: label,
    ),
  );

  /// The specification this chain describes.
  PlotSpec<T> toSpec() {
    final xLabel = _xLabel;
    final yLabel = _yLabel;
    return PlotSpec<T>(
      data: _rows,
      marks: _marks,
      transposed: _transposed,
      theme: _theme,
      interaction: _interaction,
      xAxis: _xAxis ?? (xLabel == null ? null : XAxisConfig(label: xLabel)),
      yAxes: _yAxes.isNotEmpty || yLabel == null
          ? _yAxes
          : <YAxisConfig>[
              YAxisConfig(position: YAxisPosition.left, label: yLabel),
            ],
      grid: _grid,
      title: _title,
      subtitle: _subtitle,
      showLegend: _showLegend,
      facet: _facet,
    );
  }

  /// Renders this chain as a single panel.
  ///
  /// The host-facing parameters are the ones [BravenPlot] exposes; everything
  /// about the chart itself comes from the chain. A faceted chain is rejected
  /// here with [GrammarDiagnosticCode.facetedSpecNotLowerable] — render it with
  /// [buildFaceted] instead.
  BravenPlot<T> build({
    Key? key,
    BravenChartController? bravenChartController,
    ChartInteractionGroupController? interactionGroupController,
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
  }) {
    final spec = toSpec();
    if (spec.facet != null) {
      throw GrammarSpecException.facetedSpecNotLowerable();
    }
    return BravenPlot<T>(
      spec,
      key: key,
      bravenChartController: bravenChartController,
      interactionGroupController: interactionGroupController,
      emptyStateConfig: emptyStateConfig,
    );
  }

  /// Renders this chain as a grid of synchronized small-multiple panels.
  ///
  /// Requires a faceted chain (`.facet(...)`); a non-faceted chain is rejected
  /// with [GrammarDiagnosticCode.notFaceted]. The grid owns its own shared
  /// interaction controller, so — unlike [build] — no per-chart controller is
  /// exposed here (a facet grid is N charts).
  BravenFacetPlot<T> buildFaceted({
    Key? key,
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
  }) {
    final spec = toSpec();
    if (spec.facet == null) throw GrammarSpecException.notFaceted();
    return BravenFacetPlot<T>(
      spec,
      key: key,
      emptyStateConfig: emptyStateConfig,
    );
  }
}
