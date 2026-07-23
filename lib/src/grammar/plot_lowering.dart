// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../models/bar_chart_style.dart' show BarOrientation;
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_data_point.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/grid_config.dart';
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
    this.grid,
    this.title,
    this.subtitle,
    this.showLegend,
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

  /// The spec's grid configuration, unchanged. Null lets the chart default it.
  final GridConfig? grid;

  /// The spec's chart title, unchanged.
  final String? title;

  /// The spec's chart subtitle, unchanged.
  final String? subtitle;

  /// The spec's legend visibility, unchanged. Null lets the chart default it.
  final bool? showLegend;
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

/// Reference-annotation prototypes, for the same reason as [_trendDefaults]:
/// none is const-constructible, so their defaults are read off an instance
/// rather than re-declared, which keeps the lowering from drifting from the
/// model's own defaults.
final ThresholdAnnotation _thresholdDefaults = ThresholdAnnotation(
  axis: AnnotationAxis.y,
  value: 0,
);
final PointAnnotation _pointDefaults = PointAnnotation(
  seriesId: '',
  dataPointIndex: 0,
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
///   [GrammarDiagnosticCode]. This is symmetric — a channel without its
///   encoding AND an encoding with no channel to drive it both raise, rather
///   than one throwing and the other going quietly inert.
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
/// first. All DATA-INDEPENDENT structural checks run before the emptyData
/// guard, so an authoring error surfaces even against a momentarily-empty
/// dataset (which is what lets `BravenPlot` swallow ONLY emptyData): empty
/// marks, mark ids, axis ids, transposition, then each mark's structural
/// checks in spec order (axis binding, scatter channel/encoding pairing,
/// trend source), then unbound axes. Only then comes empty data, followed by
/// the DATA-DEPENDENT materialization — the per-row candlestick validation
/// that cannot run on an empty dataset.
extension PlotSpecLowering<T> on PlotSpec<T> {
  /// Lowers this spec onto ordinary chart config objects.
  LoweredPlot lower() => _lower<T>(this);
}

LoweredPlot _lower<T>(PlotSpec<T> spec) {
  if (spec.facet != null) throw GrammarSpecException.facetedSpecNotLowerable();
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();

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

  // Geometries are the marks that lower to a SERIES. Derived-statistic and
  // reference marks (trend, threshold, band, point) lower to annotations and
  // are therefore never valid trend sources, so they are excluded here.
  final geometryIds = <String>{
    for (var index = 0; index < spec.marks.length; index++)
      if (spec.marks[index] is LineMark<T> ||
          spec.marks[index] is AreaMark<T> ||
          spec.marks[index] is BarMark<T> ||
          spec.marks[index] is ScatterMark<T> ||
          spec.marks[index] is CandlestickMark<T>)
        markIds[index],
  };

  // ---- Data-INDEPENDENT structural validation --------------------------
  // Everything decidable from the spec's SHAPE — not its rows — is checked
  // here, and it runs BEFORE the emptyData guard below. A spec wired against
  // an initially-empty dataset (a cleared filter, a pending fetch) therefore
  // still surfaces its authoring errors — a duplicate mark id, an unknown or
  // unbound axis, a channel without its encoding, a typo'd trend source —
  // rather than reading as a clean chart that only throws once real rows
  // arrive. This is exactly the contract BravenPlot relies on: it may swallow
  // an emptyData diagnostic and render the empty state, so emptyData must be
  // reachable ONLY for a spec that is otherwise well formed.
  //
  // Each geometry's resolved axis is captured now and reused during
  // materialization, so binding is validated (and reported) exactly once.
  final boundAxes = List<YAxisConfig?>.filled(spec.marks.length, null);
  final boundAxisIds = <String>{};
  for (var index = 0; index < spec.marks.length; index++) {
    final mark = spec.marks[index];
    final markId = markIds[index];
    switch (mark) {
      case TrendMark<T>():
        _validateTrend(mark, markId, geometryIds);
      case ScatterMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateScatterChannels(mark, markId);
      case LineMark<T>() ||
          AreaMark<T>() ||
          BarMark<T>() ||
          CandlestickMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
      case ThresholdMark<T>() || BandMark<T>() || PointMark<T>():
        // Reference marks bind no Y axis and carry no data-independent
        // structural invariant beyond what their annotation asserts on
        // construction during materialization.
        break;
    }
  }

  for (final axis in axes) {
    if (!boundAxisIds.contains(axis.id)) {
      throw GrammarSpecException.unboundAxis(axis.id);
    }
  }

  // ---- Data-DEPENDENT materialization ----------------------------------
  // Only reached once the spec is structurally sound. Anything that iterates
  // points — building the series, validating candlestick rows — lives below
  // the emptyData guard because it cannot run on an empty dataset.
  if (spec.data.isEmpty) throw GrammarSpecException.emptyData();

  final series = <ChartSeries>[];
  final annotations = <ChartAnnotation>[];
  for (var index = 0; index < spec.marks.length; index++) {
    final mark = spec.marks[index];
    final markId = markIds[index];
    final axis = boundAxes[index];
    switch (mark) {
      case LineMark<T>():
        series.add(_lowerLine(mark, markId, axis!, spec.data));
      case AreaMark<T>():
        series.add(_lowerArea(mark, markId, axis!, spec.data));
      case BarMark<T>():
        series.add(
          _lowerBar(
            mark,
            markId,
            axis!,
            spec.data,
            transposed: spec.transposed,
          ),
        );
      case ScatterMark<T>():
        series.add(_lowerScatter(mark, markId, axis!, spec.data));
      case CandlestickMark<T>():
        series.add(_lowerCandlestick(mark, markId, axis!, spec.data));
      case TrendMark<T>():
        annotations.add(_lowerTrend(mark, markId));
      case ThresholdMark<T>():
        annotations.add(_lowerThreshold(mark, markId));
      case BandMark<T>():
        annotations.add(_lowerBand(mark, markId));
      case PointMark<T>():
        annotations.add(_lowerPoint(mark, markId));
    }
  }

  return LoweredPlot(
    series: series,
    annotations: annotations,
    xAxis: spec.xAxis,
    yAxes: axes,
    interaction: spec.interaction ?? const InteractionConfig(),
    theme: spec.theme,
    grid: spec.grid,
    title: spec.title,
    subtitle: spec.subtitle,
    showLegend: spec.showLegend,
  );
}

/// Resolves and records the Y axis a geometry [mark] binds to.
///
/// Data-independent: a mark's axis binding is a property of the spec's shape,
/// so this is validated up front, before any rows are read.
YAxisConfig _bindAxis<T>(
  Mark<T> mark,
  String markId,
  List<YAxisConfig> axes,
  Map<String, YAxisConfig> axesById,
  Set<String> boundAxisIds,
) {
  final axisId = mark.yAxisId ?? axes.first.id;
  final axis = axesById[axisId];
  if (axis == null) {
    throw GrammarSpecException.unknownAxisId(markId, axisId, axesById.keys);
  }
  boundAxisIds.add(axisId);
  return axis;
}

/// Validates a scatter mark's channel/encoding pairing, without touching rows.
///
/// Every check here is decidable from the mark alone. A channel that names a
/// non-native scale, a channel missing the encoding it needs, and — the
/// mirror image — an encoding with no channel to drive it, are all authoring
/// errors that must surface even when the dataset is momentarily empty.
void _validateScatterChannels<T>(ScatterMark<T> mark, String markId) {
  _requireScale(markId, 'size', mark.size?.scale, ChannelScale.sqrt);
  _requireScale(markId, 'colorBy', mark.colorBy?.scale, ChannelScale.linear);
  _requireScale(
    markId,
    'opacityBy',
    mark.opacityBy?.scale,
    ChannelScale.linear,
  );

  if (mark.colorBy != null && mark.colorEncoding == null) {
    throw GrammarSpecException.missingChannelEncoding(
      markId,
      'colorBy',
      'Supply colorEncoding: ScatterColorEncoding(colors: [...]). The package '
          'ships no default color ramp.',
    );
  }
  if (mark.categoryBy != null && mark.categories.isEmpty) {
    throw GrammarSpecException.missingChannelEncoding(
      markId,
      'categoryBy',
      'Supply categories: [ScatterCategoryStyle(key: ..., color: ...)]. Each '
          'category must change a color or a shape, and the package ships no '
          'categorical palette.',
    );
  }

  // Orphan encodings: the reverse of the checks above. An encoding with no
  // channel to drive it is inert, and the module's contract is that nothing
  // is dropped or defaulted silently, so it is reported rather than ignored.
  if (mark.size == null && mark.sizeEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'sizeEncoding',
      'size',
    );
  }
  if (mark.colorBy == null && mark.colorEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'colorEncoding',
      'colorBy',
    );
  }
  if (mark.opacityBy == null && mark.opacityEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'opacityEncoding',
      'opacityBy',
    );
  }
  if (mark.categoryBy == null && mark.categories.isNotEmpty) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'categories',
      'categoryBy',
    );
  }
}

/// Validates a trend mark against the geometry ids in the plot, without rows.
void _validateTrend<T>(
  TrendMark<T> mark,
  String markId,
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
    throw GrammarSpecException.invalidTrendWindow(markId);
  }
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

/// Numbers the declared axes, defaulting an empty list to one left axis.
///
/// The axis synthesized here is deliberately UNLABELLED: a bare [PlotSpec]
/// has no channel label to name it with. The `.y(label:)` chain label is NOT
/// dropped — `BravenChart.toSpec()` has already turned it into a declared,
/// id-less left `YAxisConfig` carrying that label (an explicit `.yAxis()`
/// wins over it there), so by the time it reaches this function the label is
/// on `declared` and `copyWith(id:)` carries it through. Pinned by
/// `test/unit/grammar/chart_builder_test.dart` and
/// `test/unit/grammar/plot_lowering_parity_test.dart`.
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
  showDataPointMarkers:
      mark.showDataPointMarkers ?? _lineDefaults.showDataPointMarkers,
  dataPointLabels: mark.dataPointLabels ?? _lineDefaults.dataPointLabels,
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
  showDataPointMarkers:
      mark.showDataPointMarkers ?? _areaDefaults.showDataPointMarkers,
  dataPointLabels: mark.dataPointLabels ?? _areaDefaults.dataPointLabels,
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
    labelStyle: mark.labelStyle ?? _barDefaults.labelStyle,
    orientation: transposed
        ? BarOrientation.horizontal
        : _barDefaults.orientation,
  );
}

/// Materializes a scatter series. The mark's channel/encoding pairing has
/// already been validated by [_validateScatterChannels] in the structural
/// pass, so `mark.colorEncoding!` here is guaranteed non-null when `colorBy`
/// is present.
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

/// Materializes a trend annotation. The source-mark and window validation has
/// already run in the structural pass ([_validateTrend]).
TrendAnnotation _lowerTrend<T>(TrendMark<T> mark, String id) {
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

/// Materializes a threshold reference line. Reference marks carry no
/// data-dependent invariant, so this is a straight field mapping; the
/// annotation's own `value.isFinite` assert is the only guard.
ThresholdAnnotation _lowerThreshold<T>(ThresholdMark<T> mark, String id) {
  return ThresholdAnnotation(
    id: id,
    label: mark.label,
    axis: mark.axis,
    value: mark.value,
    lineColor: mark.color ?? _thresholdDefaults.lineColor,
    lineWidth: mark.strokeWidth ?? _thresholdDefaults.lineWidth,
    dashPattern: mark.dashPattern,
  );
}

/// Materializes a band. The mark's [BandMark.axis] selects whether the band
/// spans X or Y; the perpendicular pair is left null (unbounded), so the result
/// is a 1-D band. `RangeAnnotation` defaults `allowDragging`/`allowEditing` to
/// true, and those defaults are kept — a band authored through the grammar is
/// the ordinary hand-constructed range.
RangeAnnotation _lowerBand<T>(BandMark<T> mark, String id) {
  final isY = mark.axis == AnnotationAxis.y;
  return RangeAnnotation(
    id: id,
    label: mark.label,
    startX: isY ? null : mark.start,
    endX: isY ? null : mark.end,
    startY: isY ? mark.start : null,
    endY: isY ? mark.end : null,
    fillColor: mark.color,
  );
}

/// Materializes a point marker bound to one series' data point.
PointAnnotation _lowerPoint<T>(PointMark<T> mark, String id) {
  return PointAnnotation(
    id: id,
    label: mark.label,
    seriesId: mark.seriesId,
    dataPointIndex: mark.dataPointIndex,
    markerColor: mark.color ?? _pointDefaults.markerColor,
    markerSize: mark.markerSize ?? _pointDefaults.markerSize,
    markerShape: mark.markerShape ?? _pointDefaults.markerShape,
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
