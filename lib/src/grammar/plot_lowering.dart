// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/painting.dart' show Color;

import '../models/axis_scale_type.dart';
import '../models/bar_chart_style.dart' show BarOrientation;
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_data_point.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/concentric_donut_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/scatter_marker_style.dart';
import '../models/segment_style.dart';
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
    this.concentricDonutConfig,
    this.polarChartConfig,
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

  /// The concentric-donut composition config, when the lowered chart is a
  /// concentric donut. Null for every other family.
  final ConcentricDonutConfig? concentricDonutConfig;

  /// The polar pane/axis config, when the lowered chart is a polar column.
  /// Null for every other family.
  final PolarChartConfig? polarChartConfig;
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
  if (spec.isRadial) return _lowerRadial<T>(spec, markIds);
  final axes = _resolveAxes(spec.yAxes);
  final axesById = <String, YAxisConfig>{
    for (final axis in axes) axis.id: axis,
  };

  // Data-INDEPENDENT: a time or log scale positions its axis numerically, which
  // the DISCRETE SLOTS of a categorical axis contradict. The conflict is the
  // slots, so it is `isCategorical` (categories non-empty) that clashes — NOT
  // the mere presence of a CategoryAxisConfig. An empty CategoryAxisConfig
  // (categories: []) carries no slots; it is a documented label-styling carrier
  // on non-categorical axes (see XAxisConfig.effectiveTickLabelRotationDegrees /
  // effectiveTickLabelCollisionPolicy, which read categoryAxis regardless of
  // scaleType), and the render path treats it as non-categorical too. So a
  // time/log axis may attach one purely for label rotation/density. Only X can
  // carry a category axis, so the conflict is only expressible there.
  final xAxis = spec.xAxis;
  if (xAxis != null &&
      (xAxis.scaleType == AxisScaleType.time ||
          xAxis.scaleType == AxisScaleType.log) &&
      xAxis.isCategorical) {
    throw GrammarSpecException.conflictingAxisMode(
      'the x axis is a ${xAxis.scaleType.name} scale but also declares a '
      'category axis',
    );
  }

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
      case LineMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
      case AreaMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
      case CandlestickMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
      case BarMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
        _validateBarSizeChannel(mark.sizeBy, mark.sizeEncoding, markId);
      case ThresholdMark<T>() || BandMark<T>() || PointMark<T>():
        // Reference marks bind no Y axis and carry no data-independent
        // structural invariant beyond what their annotation asserts on
        // construction during materialization.
        break;
      case RadialMark<T>():
        // Unreachable: a radial spec returns via _lowerRadial before this
        // Cartesian switch runs. The arm exists only to keep the sealed
        // switch exhaustive.
        throw StateError('radial mark reached the Cartesian structural pass');
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
    if (axis != null) {
      _validateLogPositive(mark, markId, spec.xAxis, axis, spec.data);
    }
    switch (mark) {
      case LineMark<T>():
        series.add(_lowerLine(mark, markId, axis!, spec.data));
        _addColorLegend(annotations, mark.colorBy, mark.colorEncoding, spec.data);
      case AreaMark<T>():
        series.add(_lowerArea(mark, markId, axis!, spec.data));
        _addColorLegend(annotations, mark.colorBy, mark.colorEncoding, spec.data);
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
        _addColorLegend(annotations, mark.colorBy, mark.colorEncoding, spec.data);
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
      case RadialMark<T>():
        throw StateError('radial mark reached the Cartesian materialization');
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

/// Rejects a non-positive value fed to a log axis.
///
/// Data-DEPENDENT: reached only in the materialization pass, below the
/// emptyData guard, because it must read the values the mark positions. When
/// the mark's bound X axis (or its Y axis) is [AxisScaleType.log], every value
/// it positions there must be > 0 — a log scale is undefined at or below zero.
/// The first offending value is reported with the mark id. A non-finite value
/// (a NaN gap) is not `<= 0`, so it is left to the pipeline's usual
/// invalid-point handling, exactly as on a linear axis.
void _validateLogPositive<T>(
  Mark<T> mark,
  String markId,
  XAxisConfig? xAxis,
  YAxisConfig yAxis,
  List<T> data,
) {
  final xLog = xAxis?.scaleType == AxisScaleType.log;
  final yLog = yAxis.scaleType == AxisScaleType.log;
  if (!xLog && !yLog) return;

  void check(FieldAccessor<T, num> accessor) {
    for (final row in data) {
      final value = accessor(row);
      if (value <= 0) {
        throw GrammarSpecException.nonPositiveLogValue(markId, value);
      }
    }
  }

  switch (mark) {
    case LineMark<T>():
      if (xLog) check(mark.x);
      if (yLog) check(mark.y);
    case AreaMark<T>():
      if (xLog) check(mark.x);
      if (yLog) check(mark.y);
    case BarMark<T>():
      if (xLog) check(mark.x);
      if (yLog) check(mark.y);
    case ScatterMark<T>():
      if (xLog) check(mark.x);
      if (yLog) check(mark.y);
    case CandlestickMark<T>():
      if (xLog) check(mark.x);
      if (yLog) {
        check(mark.open);
        check(mark.high);
        check(mark.low);
        check(mark.close);
      }
    case TrendMark<T>() ||
        ThresholdMark<T>() ||
        BandMark<T>() ||
        PointMark<T>() ||
        RadialMark<T>():
      // These bind no geometry axis of their own; nothing to position on a
      // log scale here.
      break;
  }
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

/// Builds points whose OUTGOING segment carries a baked colour: point i's
/// `segmentStyle.color` is the ramp colour of point i's channel value (the
/// segment from i to i+1). The last point has no outgoing segment, so its
/// segmentStyle is unused; it is still set for parity with a hand-built series.
List<ChartDataPoint> _xyColorPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
) {
  final colors = _bakeChannelColors(colorBy, encoding, data);
  return <ChartDataPoint>[
    for (var i = 0; i < data.length; i++)
      ChartDataPoint(
        x: x(data[i]).toDouble(),
        y: y(data[i]).toDouble(),
        segmentStyle: colors[i] == null ? null : SegmentStyle.color(colors[i]!),
      ),
  ];
}

LineChartSeries _lowerLine<T>(
  LineMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) => LineChartSeries(
  id: id,
  name: mark.name,
  points: mark.colorBy == null
      ? _xyPoints(data, mark.x, mark.y)
      : _xyColorPoints(data, mark.x, mark.y, mark.colorBy!, mark.colorEncoding!),
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
  points: mark.colorBy == null
      ? _xyPoints(data, mark.x, mark.y)
      : _xyColorPoints(data, mark.x, mark.y, mark.colorBy!, mark.colorEncoding!),
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
    points: (mark.colorBy == null && mark.sizeBy == null)
        ? _xyPoints(data, mark.x, mark.y)
        : _barStyledPoints(
            data,
            mark.x,
            mark.y,
            mark.colorBy,
            mark.colorEncoding,
            mark.sizeBy,
            mark.sizeEncoding,
          ),
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

/// Lowers a RADIAL spec: exactly one radial geom, no Cartesian marks, no
/// Cartesian axis/grid option. The whole dataset maps to one radial series
/// (or, for a ring channel, one per ring). Validation order is deterministic
/// and matches the Cartesian contract: every data-INDEPENDENT structural check
/// runs before the emptyData guard, so BravenPlot swallows ONLY an otherwise
/// well-formed empty spec.
LoweredPlot _lowerRadial<T>(PlotSpec<T> spec, List<String> markIds) {
  final radialIndices = <int>[
    for (var index = 0; index < spec.marks.length; index++)
      if (spec.marks[index] is RadialMark<T>) index,
  ];
  if (radialIndices.length > 1) {
    throw GrammarSpecException.multipleRadialGeoms(<String>[
      for (final index in radialIndices) markIds[index],
    ]);
  }
  final markIndex = radialIndices.single;
  if (spec.marks.length > 1) {
    throw GrammarSpecException.mixedCoordinateSystems(
      markIds[markIndex],
      <String>[
        for (var index = 0; index < spec.marks.length; index++)
          if (index != markIndex) markIds[index],
      ],
    );
  }

  final mark = spec.marks[markIndex] as RadialMark<T>;
  final markId = markIds[markIndex];

  // Cartesian-only options carry no meaning on a radial spec.
  if (spec.transposed) {
    throw GrammarSpecException.axisOptionOnRadialSpec('transposed');
  }
  if (spec.xAxis != null) {
    throw GrammarSpecException.axisOptionOnRadialSpec('xAxis');
  }
  if (spec.yAxes.isNotEmpty) {
    throw GrammarSpecException.axisOptionOnRadialSpec('yAxes');
  }
  if (spec.grid != null) {
    throw GrammarSpecException.axisOptionOnRadialSpec('grid');
  }

  // Data-dependent checks live below the emptyData guard.
  if (spec.data.isEmpty) throw GrammarSpecException.emptyData();

  final hasVisibleCategory = spec.data.any(
    (row) => mark.category(row).toString().trim().isNotEmpty,
  );
  if (!hasVisibleCategory) {
    throw GrammarSpecException.emptyRadialCategories(markId);
  }

  final series = <ChartSeries>[];
  ConcentricDonutConfig? concentric;
  PolarChartConfig? polar;

  if (mark is PieMark<T>) {
    series.add(_lowerPie<T>(mark, markId, spec.data));
  } else if (mark is DonutMark<T>) {
    if (mark.ring == null) {
      series.add(_lowerDonut<T>(mark, markId, spec.data));
    } else {
      final rings = _lowerConcentricRings<T>(mark, markId, spec.data);
      if (rings.length == 1) {
        // A single-value ring collapses to a plain donut. The render path only
        // reads `ConcentricDonutConfig.centerContent` when more than one donut
        // series is present, so the lone ring must carry the mark's center on
        // itself — exactly like the ring-less donut path — or the center is
        // silently hidden.
        series.add(
          rings.single.copyWith(
            centerContent: mark.center ?? DonutCenterContent.hidden,
          ),
        );
        concentric = const ConcentricDonutConfig();
      } else {
        series.addAll(rings);
        concentric = mark.center == null
            ? const ConcentricDonutConfig()
            : ConcentricDonutConfig(centerContent: mark.center!);
      }
    }
  } else if (mark is PolarMark<T>) {
    series.add(_lowerPolar<T>(mark, markId, spec.data));
    polar = const PolarChartConfig();
  } else {
    throw StateError('Unhandled radial mark: $mark');
  }

  return LoweredPlot(
    series: series,
    annotations: const <ChartAnnotation>[],
    xAxis: null,
    yAxes: const <YAxisConfig>[],
    interaction: spec.interaction ?? const InteractionConfig(),
    theme: spec.theme,
    grid: null,
    title: spec.title,
    subtitle: spec.subtitle,
    showLegend: spec.showLegend,
    concentricDonutConfig: concentric,
    polarChartConfig: polar,
  );
}

/// Builds an insertion-ordered category→value map, failing loud on a repeated
/// category rather than collapsing it.
///
/// A duplicate category would otherwise silently collapse (last row wins) via
/// the families' `fromMap`; the module's contract is that nothing is dropped or
/// defaulted silently, so a repeat raises [GrammarDiagnosticCode
/// .duplicateRadialCategory] instead. The identity key is `category.toString()`
/// — exactly the key the map uses — so the check matches the collapse it
/// replaces.
///
/// Scoping is a property of the CALL, not this function: [_lowerConcentricRings]
/// calls it once per ring bucket, so a category repeated across different rings
/// (the legitimate concentric shape) never lands in the same map and is
/// accepted, while pie/donut/polar call it once over the whole dataset, so their
/// categories must be unique globally.
Map<String, num> _radialValues<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, num> value,
) {
  final result = <String, num>{};
  for (final row in data) {
    final key = category(row).toString();
    if (result.containsKey(key)) {
      throw GrammarSpecException.duplicateRadialCategory(key);
    }
    result[key] = value(row);
  }
  return result;
}

/// Builds the per-category second-metric radius map for a variable-radius geom.
Map<String, num> _radiusValues<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, num> radius,
) {
  final result = <String, num>{};
  for (final row in data) {
    result[category(row).toString()] = radius(row);
  }
  return result;
}

PieChartSeries _lowerPie<T>(PieMark<T> mark, String id, List<T> data) =>
    PieChartSeries.fromMap(
      id: id,
      name: mark.name,
      color: mark.color,
      values: _radialValues(data, mark.category, mark.value),
      radiusValues: mark.radius == null
          ? const <String, num>{}
          : _radiusValues(data, mark.category, mark.radius!),
      pieStyle: mark.style ?? const PieChartStyle(),
      dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
    );

DonutChartSeries _lowerDonut<T>(DonutMark<T> mark, String id, List<T> data) =>
    DonutChartSeries.fromMap(
      id: id,
      name: mark.name,
      color: mark.color,
      values: _radialValues(data, mark.category, mark.value),
      radiusValues: mark.radius == null
          ? const <String, num>{}
          : _radiusValues(data, mark.category, mark.radius!),
      donutStyle: mark.style ?? const DonutChartStyle(),
      centerContent: mark.center ?? DonutCenterContent.hidden,
      dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
    );

/// Partitions [data] by the donut mark's ring accessor (first-seen order) and
/// builds one `DonutChartSeries` per ring. The shared center is carried by the
/// composition's `ConcentricDonutConfig`, so each ring donut's own center is
/// hidden.
List<DonutChartSeries> _lowerConcentricRings<T>(
  DonutMark<T> mark,
  String markId,
  List<T> data,
) {
  final order = <String>[];
  final buckets = <String, List<T>>{};
  for (final row in data) {
    final key = mark.ring!(row).toString();
    buckets.putIfAbsent(key, () {
      order.add(key);
      return <T>[];
    }).add(row);
  }
  return <DonutChartSeries>[
    for (final key in order)
      DonutChartSeries.fromMap(
        id: '$markId-$key',
        name: key,
        values: _radialValues(buckets[key]!, mark.category, mark.value),
        radiusValues: mark.radius == null
            ? const <String, num>{}
            : _radiusValues(buckets[key]!, mark.category, mark.radius!),
        donutStyle: mark.style ?? const DonutChartStyle(),
        centerContent: DonutCenterContent.hidden,
        dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
      ),
  ];
}

PolarColumnChartSeries _lowerPolar<T>(
  PolarMark<T> mark,
  String id,
  List<T> data,
) => PolarColumnChartSeries.fromMap(
  id: id,
  name: mark.name,
  color: mark.color,
  values: _radialValues(data, mark.category, mark.value),
  polarStyle: mark.style ?? const PolarColumnStyle(),
);

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

/// The finite [min, max] of [accessor] over [data], or null when nothing is
/// finite (in which case the channel bakes no colours and emits no legend).
({double min, double max})? _finiteDomain<T>(
  FieldAccessor<T, num> accessor,
  List<T> data,
) {
  double? lo;
  double? hi;
  for (final row in data) {
    final v = accessor(row).toDouble();
    if (!v.isFinite) continue;
    if (lo == null || v < lo) lo = v;
    if (hi == null || v > hi) hi = v;
  }
  return lo == null || hi == null ? null : (min: lo, max: hi);
}

/// Per-row baked colour for [colorBy] under [encoding]. Null where the value
/// is non-finite or the domain is empty, so that element keeps its base colour.
List<Color?> _bakeChannelColors<T>(
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
  List<T> data,
) {
  final domain = _finiteDomain(colorBy.accessor, data);
  return <Color?>[
    for (final row in data)
      domain == null
          ? null
          : encoding.colorFor(
              colorBy.accessor(row).toDouble(),
              resolvedMinimumValue: domain.min,
              resolvedMaximumValue: domain.max,
            ),
  ];
}

/// A colour-ramp legend for a baked colour channel, mirroring
/// `BravenChartPlus._buildAutomaticColorLegends` (which is scatter-only, so a
/// baked non-scatter colour would otherwise carry no legend). Null when the
/// encoding hides its legend, is an invalid piecewise config, or has no finite
/// domain.
LegendAnnotation? _channelColorLegend<T>(
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
  List<T> data,
) {
  if (!encoding.showLegend) return null;
  if (!encoding.hasValidPiecewiseConfiguration) return null;
  var minimum = encoding.minimumValue ?? double.infinity;
  var maximum = encoding.maximumValue ?? double.negativeInfinity;
  for (final row in data) {
    final value = colorBy.accessor(row).toDouble();
    if (!value.isFinite) continue;
    if (encoding.minimumValue == null && value < minimum) minimum = value;
    if (encoding.maximumValue == null && value > maximum) maximum = value;
  }
  if (!minimum.isFinite && maximum.isFinite) minimum = maximum;
  if (!maximum.isFinite && minimum.isFinite) maximum = minimum;
  if (!minimum.isFinite || !maximum.isFinite) return null;
  final midpoint = (minimum + maximum) / 2;
  return LegendAnnotation(
    colorScale: LegendColorScale(
      label: colorBy.label ?? encoding.label,
      colors: encoding.colors,
      type: encoding.scaleType == ScatterColorScaleType.piecewise
          ? LegendColorScaleType.piecewise
          : LegendColorScaleType.continuous,
      segmentLabels: encoding.scaleType == ScatterColorScaleType.piecewise
          ? encoding.effectiveBandLabels
          : const <String>[],
      minimumLabel: encoding.format(minimum),
      midpointLabel: minimum == maximum ? null : encoding.format(midpoint),
      maximumLabel: encoding.format(maximum),
    ),
  );
}

/// Appends a colour-ramp legend for [colorBy]/[colorEncoding] if present.
void _addColorLegend<T>(
  List<ChartAnnotation> annotations,
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  List<T> data,
) {
  if (colorBy == null || colorEncoding == null) return;
  final legend = _channelColorLegend(colorBy, colorEncoding, data);
  if (legend != null) annotations.add(legend);
}

/// Structural validation of a non-scatter colour channel: symmetric
/// missing/orphan-encoding checks and the native-scale check (colour is linear).
void _validateColorChannel<T>(
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  String markId,
) {
  _requireScale(markId, 'colorBy', colorBy?.scale, ChannelScale.linear);
  if (colorBy != null && colorEncoding == null) {
    throw GrammarSpecException.missingChannelEncoding(
      markId,
      'colorBy',
      'Supply colorEncoding: ScatterColorEncoding(colors: [...]). The package '
          'ships no default color ramp.',
    );
  }
  if (colorBy == null && colorEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'colorEncoding',
      'colorBy',
    );
  }
}

/// Bar width channel default range (multipliers). A bar at the domain minimum
/// is 0.3x the base width; the maximum is full width.
const ScatterSizeEncoding _barSizeMultiplierDefault = ScatterSizeEncoding(
  minimumRadius: 0.3,
  maximumRadius: 1.0,
);

/// Per-row baked width multiplier: [sizeBy]'s value mapped LINEARLY into
/// `[encoding.minimumRadius, encoding.maximumRadius]`. Null where non-finite or
/// the domain is empty (that bar keeps its base width).
List<double?> _bakeChannelWidths<T>(
  Channel<T> sizeBy,
  ScatterSizeEncoding encoding,
  List<T> data,
) {
  final domain = _finiteDomain(sizeBy.accessor, data);
  final span = domain == null ? 0.0 : domain.max - domain.min;
  return <double?>[
    for (final row in data)
      () {
        final v = sizeBy.accessor(row).toDouble();
        if (!v.isFinite || domain == null) return null;
        final t = span <= 0 ? 0.5 : ((v - domain.min) / span).clamp(0.0, 1.0);
        return encoding.minimumRadius +
            t * (encoding.maximumRadius - encoding.minimumRadius);
      }(),
  ];
}

/// Structural validation of the bar size channel: native scale is linear, and
/// a sizeEncoding with no sizeBy is an orphan. (sizeBy without sizeEncoding is
/// allowed; it uses [_barSizeMultiplierDefault].)
void _validateBarSizeChannel<T>(
  Channel<T>? sizeBy,
  ScatterSizeEncoding? sizeEncoding,
  String markId,
) {
  _requireScale(markId, 'sizeBy', sizeBy?.scale, ChannelScale.linear);
  if (sizeBy == null && sizeEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'sizeEncoding',
      'sizeBy',
    );
  }
}

/// Builds bar points, weaving a baked colour (and, in Task 4, width) into
/// `pointStyle`. A point whose channels produce nothing keeps a null pointStyle.
List<ChartDataPoint> _barStyledPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  Channel<T>? sizeBy,
  ScatterSizeEncoding? sizeEncoding,
) {
  final colors = colorBy == null
      ? null
      : _bakeChannelColors(colorBy, colorEncoding!, data);
  final widths = sizeBy == null
      ? null
      : _bakeChannelWidths(
          sizeBy,
          sizeEncoding ?? _barSizeMultiplierDefault,
          data,
        );
  return <ChartDataPoint>[
    for (var i = 0; i < data.length; i++)
      ChartDataPoint(
        x: x(data[i]).toDouble(),
        y: y(data[i]).toDouble(),
        pointStyle: (colors?[i] == null && widths?[i] == null)
            ? null
            : PointStyle(color: colors?[i], size: widths?[i]),
      ),
  ];
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
