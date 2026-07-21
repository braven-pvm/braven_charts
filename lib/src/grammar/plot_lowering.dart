// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/bar_chart_style.dart' show BarOrientation;
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_data_point.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/interaction_config.dart';
import '../models/scatter_marker_style.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'channel.dart';
import 'grammar_diagnostics.dart';
import 'mark.dart';
import 'plot_spec.dart';

/// The config objects a [PlotSpec] compiles down to.
///
/// Everything here is an ordinary member of the existing config API — the
/// render pipeline, artifact codecs, Source generation and Workbench receive
/// exactly the objects they already understand, and none of them knows the
/// grammar layer exists.
///
/// Note for the `BravenPlot` widget (Task 11): [yAxes] is the RESOLVED axis
/// list, and every entry is also attached to at least one series through
/// `ChartSeries.yAxisConfig`, which is what activates the multi-axis path.
/// The widget passes [series], [annotations], [xAxis], [interaction] and
/// [theme] to `BravenChartPlus` and must NOT pass a widget-level `yAxis`:
/// doing so would re-enter the legacy single-axis path this lowering
/// deliberately avoids.
class LoweredPlot {
  /// Bundles one lowering result.
  const LoweredPlot({
    required this.series,
    required this.annotations,
    required this.xAxis,
    required this.yAxes,
    required this.interaction,
    required this.theme,
  });

  /// One series per geometry mark, in spec order.
  final List<ChartSeries> series;

  /// One annotation per derived-statistic mark, in spec order.
  final List<ChartAnnotation> annotations;

  /// The spec's X-axis configuration, unchanged.
  final XAxisConfig? xAxis;

  /// Every Y axis, with ids resolved and each one bound to a series.
  final List<YAxisConfig> yAxes;

  /// The spec's interaction configuration, or the package default.
  final InteractionConfig interaction;

  /// The spec's theme, unchanged. Null lets the chart pick its own.
  final ChartTheme? theme;
}

// Const prototypes. Reading defaults off a real instance instead of
// re-declaring literals means a change to a series default cannot silently
// desynchronize the lowering from the hand-written equivalent.
const LineChartSeries _lineDefaults = LineChartSeries(
  id: '',
  points: <ChartDataPoint>[],
);
const AreaChartSeries _areaDefaults = AreaChartSeries(
  id: '',
  points: <ChartDataPoint>[],
);
const BarChartSeries _barDefaults = BarChartSeries(
  id: '',
  points: <ChartDataPoint>[],
  barWidthPercent: _defaultBarWidthPercent,
);
const ScatterChartSeries _scatterDefaults = ScatterChartSeries(
  id: '',
  points: <ChartDataPoint>[],
);
const ScatterCategoryEncoding _categoryDefaults = ScatterCategoryEncoding(
  categories: <ScatterCategoryStyle>[],
);

/// `BarChartSeries` requires one of width-percent or width-pixels, and has no
/// default of its own. 0.8 is the value the rest of the package uses.
const double _defaultBarWidthPercent = 0.8;

/// `TrendAnnotation` is not const-constructible (it generates an id), so its
/// defaults are read off a lazily created prototype instead.
final TrendAnnotation _trendDefaults = TrendAnnotation(
  seriesId: '',
  trendType: TrendType.linear,
);

/// Compiles a [PlotSpec] into the config objects the chart pipeline consumes.
///
/// This is an EXTENSION rather than a top-level `lower<T>(spec)` function on
/// purpose: `lower` is a generic English verb, and a package-level export of
/// that name would collide with every host that already has one. Written as
/// `spec.lower()`, the verb is scoped to the receiver it means something for
/// and never enters a host's global namespace.
///
/// ## Guarantees
///
/// * Every chart takes the MULTI-AXIS path. [PlotSpec.yAxes] defaults to a
///   single left axis, each axis gets a resolved id (`axis-<index>` when the
///   caller left it empty), and every series carries both `yAxisId` and the
///   matching `yAxisConfig`.
/// * A mark without an `id` becomes `mark-<index>`, counting trend marks, so
///   ids are stable against restyling and unaffected by which marks are
///   geometries.
/// * Nothing is dropped or defaulted silently: anything the config surface
///   cannot express raises a [GrammarSpecException] with a
///   [GrammarDiagnosticCode].
///
/// ## Non-finite values
///
/// Accessor output is materialized VERBATIM for the point-based families
/// (line, area, bar, scatter). `ChartDataPoint` documents that x and y may be
/// NaN or infinite and exposes `isValid`; every consumer in the pipeline —
/// bounds, hit-testing, crosshair, value summary, rendering — already skips
/// invalid points, which is how a gap in a line series is expressed. Throwing
/// here would make the grammar layer stricter than the API it lowers onto and
/// would remove the only way to express a gap.
///
/// Candlesticks are the exception, because `CandlestickDataPoint` itself
/// rejects non-finite values and violated OHLC invariants. Those rows are
/// validated up front and reported as
/// [GrammarDiagnosticCode.invalidCandlestickRow] with the row index, rather
/// than surfacing as a raw `ArgumentError` from deep inside the model.
///
/// ## Validation order
///
/// Deterministic, so a spec with several problems always reports the same one
/// first: empty marks, empty data, mark ids, axis ids, transposition, then
/// each mark in spec order, then unbound axes.
extension PlotSpecLowering<T> on PlotSpec<T> {
  /// Lowers this spec onto ordinary chart config objects.
  LoweredPlot lower() => _lower<T>(this);
}

LoweredPlot _lower<T>(PlotSpec<T> spec) {
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();
  if (spec.data.isEmpty) throw GrammarSpecException.emptyData();

  final markIds = _resolveMarkIds(spec.marks);
  final axes = _resolveAxes(spec.yAxes);
  final axesById = <String, YAxisConfig>{
    for (final axis in axes) axis.id: axis,
  };

  if (spec.transposed) {
    for (var index = 0; index < spec.marks.length; index++) {
      if (spec.marks[index] is! BarMark<T>) {
        throw GrammarSpecException.unsupportedTransposition(markIds[index]);
      }
    }
  }

  final geometryIds = <String>{
    for (var index = 0; index < spec.marks.length; index++)
      if (spec.marks[index] is! TrendMark<T>) markIds[index],
  };

  final series = <ChartSeries>[];
  final annotations = <ChartAnnotation>[];
  final boundAxisIds = <String>{};

  YAxisConfig bind(Mark<T> mark, String markId) {
    final axisId = mark.yAxisId ?? axes.first.id;
    final axis = axesById[axisId];
    if (axis == null) {
      throw GrammarSpecException.unknownAxisId(markId, axisId, axesById.keys);
    }
    boundAxisIds.add(axisId);
    return axis;
  }

  for (var index = 0; index < spec.marks.length; index++) {
    final mark = spec.marks[index];
    final markId = markIds[index];
    switch (mark) {
      case LineMark<T>():
        series.add(_lowerLine(mark, markId, bind(mark, markId), spec.data));
      case AreaMark<T>():
        series.add(_lowerArea(mark, markId, bind(mark, markId), spec.data));
      case BarMark<T>():
        series.add(
          _lowerBar(
            mark,
            markId,
            bind(mark, markId),
            spec.data,
            transposed: spec.transposed,
          ),
        );
      case ScatterMark<T>():
        series.add(_lowerScatter(mark, markId, bind(mark, markId), spec.data));
      case CandlestickMark<T>():
        series.add(
          _lowerCandlestick(mark, markId, bind(mark, markId), spec.data),
        );
      case TrendMark<T>():
        annotations.add(_lowerTrend(mark, markId, geometryIds));
    }
  }

  for (final axis in axes) {
    if (!boundAxisIds.contains(axis.id)) {
      throw GrammarSpecException.unboundAxis(axis.id);
    }
  }

  return LoweredPlot(
    series: series,
    annotations: annotations,
    xAxis: spec.xAxis,
    yAxes: axes,
    interaction: spec.interaction ?? const InteractionConfig(),
    theme: spec.theme,
  );
}

List<String> _resolveMarkIds<T>(List<Mark<T>> marks) {
  final ids = <String>[];
  final seen = <String>{};
  for (var index = 0; index < marks.length; index++) {
    final id = marks[index].id ?? 'mark-$index';
    if (!seen.add(id)) throw GrammarSpecException.duplicateMarkId(id);
    ids.add(id);
  }
  return ids;
}

List<YAxisConfig> _resolveAxes(List<YAxisConfig> declared) {
  final source = declared.isEmpty
      ? <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)]
      : declared;
  final resolved = <YAxisConfig>[];
  final seen = <String>{};
  for (var index = 0; index < source.length; index++) {
    final axis = source[index];
    final withId = axis.id.isEmpty ? axis.copyWith(id: 'axis-$index') : axis;
    if (!seen.add(withId.id)) {
      throw GrammarSpecException.duplicateAxisId(withId.id);
    }
    resolved.add(withId);
  }
  return resolved;
}

List<ChartDataPoint> _xyPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
) => <ChartDataPoint>[
  for (final row in data)
    ChartDataPoint(x: x(row).toDouble(), y: y(row).toDouble()),
];

LineChartSeries _lowerLine<T>(
  LineMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) => LineChartSeries(
  id: id,
  name: mark.name,
  points: _xyPoints(data, mark.x, mark.y),
  color: mark.color,
  yAxisId: axis.id,
  yAxisConfig: axis,
  interpolation: mark.interpolation ?? _lineDefaults.interpolation,
  strokeWidth: mark.strokeWidth ?? _lineDefaults.strokeWidth,
  dashPattern: mark.dashPattern ?? _lineDefaults.dashPattern,
);

AreaChartSeries _lowerArea<T>(
  AreaMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) => AreaChartSeries(
  id: id,
  name: mark.name,
  points: _xyPoints(data, mark.x, mark.y),
  color: mark.color,
  yAxisId: axis.id,
  yAxisConfig: axis,
  interpolation: mark.interpolation ?? _areaDefaults.interpolation,
  strokeWidth: mark.strokeWidth ?? _areaDefaults.strokeWidth,
  fillOpacity: mark.fillOpacity ?? _areaDefaults.fillOpacity,
  baselineValue: mark.baseline,
  dashPattern: mark.dashPattern ?? _areaDefaults.dashPattern,
);

BarChartSeries _lowerBar<T>(
  BarMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data, {
  required bool transposed,
}) {
  // BarChartSeries asserts that exactly one width channel is supplied; the
  // grammar's default only applies when the caller named neither.
  final widthPercent = mark.barWidthPercent;
  final widthPixels = mark.barWidthPixels;
  return BarChartSeries(
    id: id,
    name: mark.name,
    points: _xyPoints(data, mark.x, mark.y),
    color: mark.color,
    yAxisId: axis.id,
    yAxisConfig: axis,
    barWidthPercent:
        widthPercent ?? (widthPixels == null ? _defaultBarWidthPercent : null),
    barWidthPixels: widthPixels,
    barGap: mark.barGap ?? _barDefaults.barGap,
    layoutMode: mark.layoutMode ?? _barDefaults.layoutMode,
    groupId: mark.groupId,
    baselineValue: mark.baselineValue ?? _barDefaults.baselineValue,
    orientation: transposed
        ? BarOrientation.horizontal
        : _barDefaults.orientation,
  );
}

ScatterChartSeries _lowerScatter<T>(
  ScatterMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) {
  final size = mark.size;
  final colorBy = mark.colorBy;
  final opacityBy = mark.opacityBy;
  final categoryBy = mark.categoryBy;

  _requireScale(id, 'size', size?.scale, ChannelScale.sqrt);
  _requireScale(id, 'colorBy', colorBy?.scale, ChannelScale.linear);
  _requireScale(id, 'opacityBy', opacityBy?.scale, ChannelScale.linear);

  if (colorBy != null && mark.colorEncoding == null) {
    throw GrammarSpecException.missingChannelEncoding(
      id,
      'colorBy',
      'Supply colorEncoding: ScatterColorEncoding(colors: [...]). The package '
          'ships no default color ramp.',
    );
  }
  if (categoryBy != null && mark.categories.isEmpty) {
    throw GrammarSpecException.missingChannelEncoding(
      id,
      'categoryBy',
      'Supply categories: [ScatterCategoryStyle(key: ..., color: ...)]. Each '
          'category must change a color or a shape, and the package ships no '
          'categorical palette.',
    );
  }

  return ScatterChartSeries(
    id: id,
    name: mark.name,
    points: <ChartDataPoint>[
      for (final row in data)
        ChartDataPoint(
          x: mark.x(row).toDouble(),
          y: mark.y(row).toDouble(),
          magnitude: size == null ? null : size.accessor(row).toDouble(),
          colorValue: colorBy == null ? null : colorBy.accessor(row).toDouble(),
          opacityValue: opacityBy == null
              ? null
              : opacityBy.accessor(row).toDouble(),
          categoryValue: categoryBy == null
              ? null
              : categoryBy.accessor(row).toString(),
        ),
    ],
    color: mark.color,
    yAxisId: axis.id,
    yAxisConfig: axis,
    markerRadius: mark.markerRadius ?? _scatterDefaults.markerRadius,
    markerShape: mark.markerShape ?? _scatterDefaults.markerShape,
    markerStyle: mark.markerStyle,
    sizeEncoding: size == null
        ? null
        : _relabelSize(mark.sizeEncoding ?? const ScatterSizeEncoding(), size),
    colorEncoding: colorBy == null
        ? null
        : _relabelColor(mark.colorEncoding!, colorBy),
    opacityEncoding: opacityBy == null
        ? null
        : _relabelOpacity(
            mark.opacityEncoding ?? const ScatterOpacityEncoding(),
            opacityBy,
          ),
    categoryEncoding: categoryBy == null
        ? null
        : ScatterCategoryEncoding(
            categories: mark.categories,
            label: categoryBy.label ?? _categoryDefaults.label,
            showLegend: _categoryDefaults.showLegend,
          ),
  );
}

CandlestickChartSeries _lowerCandlestick<T>(
  CandlestickMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) {
  final points = <CandlestickDataPoint>[];
  for (var index = 0; index < data.length; index++) {
    final row = data[index];
    final x = mark.x(row).toDouble();
    if (index > 0 && x <= points[index - 1].x) {
      throw GrammarSpecException.invalidCandlestickRow(
        id,
        index,
        'x ($x) must be strictly greater than the previous row\'s x '
        '(${points[index - 1].x}). Candlestick data must be sorted.',
      );
    }
    try {
      points.add(
        CandlestickDataPoint(
          x: x,
          open: mark.open(row).toDouble(),
          high: mark.high(row).toDouble(),
          low: mark.low(row).toDouble(),
          close: mark.close(row).toDouble(),
          timestamp: mark.timestamp?.call(row),
        ),
      );
    } on ArgumentError catch (error) {
      throw GrammarSpecException.invalidCandlestickRow(
        id,
        index,
        '${error.name ?? 'value'} ${error.message}.',
      );
    }
  }
  return CandlestickChartSeries(
    id: id,
    name: mark.name,
    points: points,
    color: mark.color,
    yAxisId: axis.id,
    yAxisConfig: axis,
  );
}

TrendAnnotation _lowerTrend<T>(
  TrendMark<T> mark,
  String id,
  Set<String> geometryIds,
) {
  if (!geometryIds.contains(mark.sourceMarkId)) {
    throw GrammarSpecException.unknownTrendSource(
      mark.sourceMarkId,
      geometryIds,
    );
  }
  // Mirrors TrendAnnotation's own assert rather than inventing a rule.
  if (mark.trendType == TrendType.movingAverage &&
      (mark.windowSize == null || mark.windowSize! <= 0)) {
    throw GrammarSpecException.invalidTrendWindow(id);
  }
  return TrendAnnotation(
    id: id,
    label: mark.name,
    seriesId: mark.sourceMarkId,
    trendType: mark.trendType,
    windowSize: mark.windowSize,
    showConfidenceBand: mark.showConfidenceBand,
    lineColor: mark.color ?? _trendDefaults.lineColor,
    lineWidth: mark.lineWidth ?? _trendDefaults.lineWidth,
    dashPattern: mark.dashPattern,
  );
}

void _requireScale(
  String markId,
  String channel,
  ChannelScale? requested,
  ChannelScale native,
) {
  if (requested != null && requested != native) {
    throw GrammarSpecException.unsupportedChannelScale(
      markId,
      channel,
      requested.name,
      native.name,
    );
  }
}

// A Channel's label, when it has one, is authoritative: it is where a reader
// looks for the measure's name. The encodings have no copyWith, so the
// override is applied by reconstruction.
ScatterSizeEncoding _relabelSize<T>(
  ScatterSizeEncoding template,
  Channel<T> channel,
) => channel.label == null
    ? template
    : ScatterSizeEncoding(
        minimumRadius: template.minimumRadius,
        maximumRadius: template.maximumRadius,
        minimumValue: template.minimumValue,
        maximumValue: template.maximumValue,
        label: channel.label!,
        unit: template.unit,
        showLegend: template.showLegend,
      );

ScatterColorEncoding _relabelColor<T>(
  ScatterColorEncoding template,
  Channel<T> channel,
) => channel.label == null
    ? template
    : ScatterColorEncoding(
        colors: template.colors,
        scaleType: template.scaleType,
        thresholds: template.thresholds,
        bandLabels: template.bandLabels,
        minimumValue: template.minimumValue,
        maximumValue: template.maximumValue,
        label: channel.label!,
        unit: template.unit,
        showLegend: template.showLegend,
      );

ScatterOpacityEncoding _relabelOpacity<T>(
  ScatterOpacityEncoding template,
  Channel<T> channel,
) => channel.label == null
    ? template
    : ScatterOpacityEncoding(
        minimumOpacity: template.minimumOpacity,
        maximumOpacity: template.maximumOpacity,
        minimumValue: template.minimumValue,
        maximumValue: template.maximumValue,
        label: channel.label!,
        unit: template.unit,
        showLegend: template.showLegend,
      );
