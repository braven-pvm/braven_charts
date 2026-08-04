// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/painting.dart' show Color;

import '../layout/concentric_donut_layout.dart';
import '../layout/polar_column_composition.dart';
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
import '../models/heatmap_chart_series.dart';
import '../models/heatmap_color_scale.dart';
import '../models/heatmap_data_point.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_selection_style.dart';
import '../models/range_area_chart_series.dart';
import '../models/range_area_data_point.dart';
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
/// Note for the `BravenPlot` widget: [yAxes] is the RESOLVED axis list, and
/// every entry is also attached to at least one series through
/// `ChartSeries.yAxisConfig`, which is what activates the multi-axis path. The
/// widget passes [series], [annotations], [xAxis], [interaction] and [theme] to
/// `BravenChartPlus`.
///
/// It passes a widget-level `yAxis` in exactly ONE shape, and that is
/// deliberate — this note previously forbade it outright. When the lowered plot
/// declares one axis and no mark names it, the widget re-mounts the plot the
/// way a config author writes it: `yAxis:` set and the series' bindings
/// stripped. That is not "re-entering" a path the lowering avoids, it is
/// reproducing the chart the chain was reversed FROM. Without it every
/// single-axis chain hands back a document carrying `series[*].axisId` plus
/// `inlineAxis` that the equivalent config chart does not have, and the
/// grammar's round trip cannot be gated on document equality. Every other
/// shape — several axes, or a mark naming its axis — still gets no widget-level
/// `yAxis` at all, and a `BravenFacetPlot` panel is held to the multi-axis
/// mount explicitly. See `braven_plot.dart` and `FacetPanelScope`.
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
  /// concentric donut. Null for every other family — INCLUDING a ring-less
  /// donut, which refuses `DonutMark.concentric` by name rather than carrying
  /// a config it composes nothing for. `ChartGrammarSourceGenerator` relies on
  /// that: it treats a non-null config as the authoritative "this is a
  /// concentric composition" discriminator.
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
final HeatmapChartSeries _heatmapDefaults = HeatmapChartSeries(
  id: '',
  points: const <HeatmapDataPoint>[],
  colorScale: HeatmapColorScale.sequential(
    colors: const <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
    showLegend: false,
  ),
);
const ScatterCategoryEncoding _categoryDefaults = ScatterCategoryEncoding(
  categories: <ScatterCategoryStyle>[],
);

/// Not `const`: `RangeAreaChartSeries` validates in its constructor body. Read
/// only for its DEFAULTS, so the empty point list is deliberate.
final RangeAreaChartSeries _rangeAreaDefaults = RangeAreaChartSeries(
  id: '',
  points: const <RangeAreaDataPoint>[],
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
/// * Every LOWERING takes the multi-axis path. [PlotSpec.yAxes] defaults to a
///   single left axis, each axis gets a resolved id (`axis-<index>` when the
///   caller left it empty), and every series carries both `yAxisId` and the
///   matching `yAxisConfig`. This is a guarantee about what [LoweredPlot]
///   holds, NOT about how the chart is mounted: `BravenPlot` re-mounts the
///   one-axis-no-explicit-binding shape as the legacy single-axis chart (see
///   [LoweredPlot]'s own note). Lowering itself never produces an unbound
///   series.
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
/// marks, mark ids, misplaced `.polarConfig(...)`, axis ids, transposition,
/// then each mark's structural checks in spec order (axis binding, scatter
/// channel/encoding pairing, trend source, per-point key collisions), then
/// unbound axes. Only then comes empty data, followed by the DATA-DEPENDENT
/// materialization — the per-row candlestick validation that cannot run on an
/// empty dataset.
///
/// The point-key collision check is the one member of that list that reads
/// ROWS. It sits there anyway because it condemns the AUTHORING — one accessor
/// that cannot distinguish two observations — and because nothing is lost by
/// the placement: an empty dataset has no keys to collide, so `emptyData` is
/// still what surfaces for it. See [_validatePointKeys].
///
/// The radial branch follows the same rule: coordinate-system and radial-family
/// checks, Cartesian-option checks, the `.polarConfig(...)` placement check and
/// the SHAPE half of the polar composition contract (clashing mark units, a
/// grouped/stacked composition with fewer than two polar marks, a
/// half-specified interval, clashing mark presets) all run above the emptyData
/// guard; the row-dependent half — visible categories, and the
/// `PolarColumnComposition.validate` pass over the lowered series — runs below
/// it.
extension PlotSpecLowering<T> on PlotSpec<T> {
  /// Lowers this spec onto ordinary chart config objects.
  LoweredPlot lower() => _lower<T>(this);
}

LoweredPlot _lower<T>(PlotSpec<T> spec) {
  if (spec.facet != null) throw GrammarSpecException.facetedSpecNotLowerable();
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();

  final markIds = _resolveMarkIds(spec.marks);
  // Data-INDEPENDENT placement check, hoisted ABOVE the radial dispatch because
  // `.polarConfig(...)` is a PLOT-level verb every chain exposes, so the most
  // likely way to misplace it is on a Cartesian chain — which never enters
  // `_lowerRadial`. Leaving the guard there dropped the config silently, which
  // is exactly the outcome the module's contract forbids. A spec holding a
  // `PolarMark` is radial by definition, so this fires only when the spec has no
  // polar geom at all; the radial branch keeps its own guard for the mixed
  // radial families (a pie or donut spec), where `mixedCoordinateSystems` and
  // `multipleRadialGeoms` must be reported first.
  if (spec.polar != null && !spec.isRadial) {
    throw GrammarSpecException.polarConfigOnNonPolarSpec(markIds.first);
  }
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

  final heatmapIds = <String>[];
  final otherGeometryIds = <String>[];
  for (var index = 0; index < spec.marks.length; index++) {
    final mark = spec.marks[index];
    if (mark is HeatmapMark<T>) {
      heatmapIds.add(markIds[index]);
    } else if (mark is LineMark<T> ||
        mark is AreaMark<T> ||
        mark is BarMark<T> ||
        mark is ScatterMark<T> ||
        mark is CandlestickMark<T>) {
      otherGeometryIds.add(markIds[index]);
    }
  }
  if (heatmapIds.length > 1 ||
      (heatmapIds.isNotEmpty && otherGeometryIds.isNotEmpty)) {
    throw GrammarSpecException.unsupportedHeatmapComposition(
      heatmapIds,
      otherGeometryIds,
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
          spec.marks[index] is CandlestickMark<T> ||
          spec.marks[index] is RangeAreaMark<T>)
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
        _validatePointKeys(mark.pointKey, markId, spec.data);
      case LineMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
        _validatePointKeys(mark.pointKey, markId, spec.data);
      case AreaMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
        _validatePointKeys(mark.pointKey, markId, spec.data);
      case CandlestickMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
      case HeatmapMark<T>():
        final axis = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
        boundAxes[index] = axis;
        _validateHeatmapConfiguration(mark, markId, axis);
      case RangeAreaMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validatePointKeys(mark.pointKey, markId, spec.data);
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
        _validatePointKeys(mark.pointKey, markId, spec.data);
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
        _addColorLegend(
          annotations,
          mark.colorBy,
          mark.colorEncoding,
          spec.data,
        );
      case AreaMark<T>():
        series.add(_lowerArea(mark, markId, axis!, spec.data));
        _addColorLegend(
          annotations,
          mark.colorBy,
          mark.colorEncoding,
          spec.data,
        );
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
        _addColorLegend(
          annotations,
          mark.colorBy,
          mark.colorEncoding,
          spec.data,
        );
      case ScatterMark<T>():
        series.add(_lowerScatter(mark, markId, axis!, spec.data));
      case CandlestickMark<T>():
        series.add(_lowerCandlestick(mark, markId, axis!, spec.data));
      case HeatmapMark<T>():
        series.add(_lowerHeatmap(mark, markId, axis!, spec.xAxis, spec.data));
      case RangeAreaMark<T>():
        series.add(_lowerRangeArea(mark, markId, axis!, spec.data));
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
    case HeatmapMark<T>():
      if (xLog) check(mark.x);
      if (yLog) check(mark.y);
    case RangeAreaMark<T>():
      if (xLog) check(mark.x);
      if (yLog) {
        // A gap positions nothing, so it cannot be non-positive. The bounds of
        // a real interval both land on the Y scale and are both checked.
        for (final row in data) {
          final low = mark.low(row);
          final high = mark.high(row);
          if (low != null && low <= 0) {
            throw GrammarSpecException.nonPositiveLogValue(markId, low);
          }
          if (high != null && high <= 0) {
            throw GrammarSpecException.nonPositiveLogValue(markId, high);
          }
        }
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

void _validateHeatmapConfiguration<T>(
  HeatmapMark<T> mark,
  String markId,
  YAxisConfig axis,
) {
  try {
    HeatmapChartSeries(
      id: markId,
      points: const <HeatmapDataPoint>[],
      colorScale: mark.colorScale,
      yAxisId: axis.id,
      yAxisConfig: axis,
      unit: mark.unit,
      cellWidth: mark.cellWidth ?? _heatmapDefaults.cellWidth,
      cellHeight: mark.cellHeight ?? _heatmapDefaults.cellHeight,
      gapFraction: mark.gapFraction ?? _heatmapDefaults.gapFraction,
      borderColor: mark.borderColor ?? _heatmapDefaults.borderColor,
      borderWidth: mark.borderWidth ?? _heatmapDefaults.borderWidth,
      cornerRadius: mark.cornerRadius ?? _heatmapDefaults.cornerRadius,
      showCellLabels: mark.showCellLabels ?? _heatmapDefaults.showCellLabels,
      cellLabelColor: mark.cellLabelColor,
      cellLabelFontSize:
          mark.cellLabelFontSize ?? _heatmapDefaults.cellLabelFontSize,
      emptyValueStyle: mark.emptyValueStyle,
      valueFilter: mark.valueFilter,
    );
  } on ArgumentError catch (error) {
    throw GrammarSpecException.invalidHeatmapConfiguration(
      markId,
      '${error.name ?? 'value'} ${error.message}.',
    );
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

/// Rejects a [pointKey] accessor that yields the same key for two rows of one
/// mark.
///
/// A `pointKey` is the STABLE IDENTITY of one observation within its series —
/// what selection, hit-testing and bounded-stream eviction are expressed
/// against — so a repeat makes every such expression ambiguous. The radial side
/// already refuses the equivalent collision (`duplicateRadialCategory`, raised
/// by `_radialValues`); this is the Cartesian one.
///
/// Scoping is per MARK, matching `ChartDataPoint.pointKey`'s own contract
/// ("unique among the keyed points in one series"): two marks that key their
/// rows the same way are the ordinary shared-x chart and are accepted.
///
/// Placement: this sits with the SHAPE-decidable validations, above the
/// emptyData guard, so a key collision outranks the row-dependent
/// materialization checks below it. It does read rows — unlike its neighbours —
/// but nothing is lost by that: on an empty dataset there are no keys to
/// collide, so the loop finds nothing and `emptyData` is still what surfaces,
/// which is what keeps `BravenPlot`'s swallow-only-emptyData contract intact.
void _validatePointKeys<T>(
  FieldAccessor<T, String?>? pointKey,
  String markId,
  List<T> data,
) {
  if (pointKey == null) return;
  final seen = <String>{};
  for (final row in data) {
    // Unkeyed points are not "the same identity", they have none — so an empty
    // or absent key never collides. The normalisation matches _pointText's.
    final key = pointKey(row);
    if (key == null || key.isEmpty) continue;
    if (!seen.add(key)) {
      throw GrammarSpecException.duplicatePointKey(markId, key);
    }
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

/// Normalises a per-point text accessor's result.
///
/// An empty string means "this point has no label / no key", for two reasons
/// that point the same way. `ChartDataPoint` ASSERTS a non-empty `pointKey`, so
/// `''` is not a value that path can hold at all; and the source emitter
/// reverses both fields through a NON-NULLABLE `String` row slot, writing `''`
/// for a point that carried none — so a chain emitted from a partially labelled
/// series feeds `''` straight back through here for every bare point.
///
/// An author who genuinely wants an empty label is not silently served a
/// different chart: the emitter's round-trip proof compares points field for
/// field, so such a chart is REFUSED rather than emitted as one that drops it.
String? _pointText<T>(FieldAccessor<T, String?>? accessor, T row) {
  final text = accessor?.call(row);
  return (text == null || text.isEmpty) ? null : text;
}

List<ChartDataPoint> _xyPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
  FieldAccessor<T, String?>? label,
  FieldAccessor<T, String?>? pointKey,
) => <ChartDataPoint>[
  for (final row in data)
    ChartDataPoint(
      x: x(row).toDouble(),
      y: y(row).toDouble(),
      label: _pointText(label, row),
      pointKey: _pointText(pointKey, row),
    ),
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
  FieldAccessor<T, String?>? label,
  FieldAccessor<T, String?>? pointKey,
) {
  final colors = _bakeChannelColors(colorBy, encoding, data);
  return <ChartDataPoint>[
    for (var i = 0; i < data.length; i++)
      ChartDataPoint(
        x: x(data[i]).toDouble(),
        y: y(data[i]).toDouble(),
        label: _pointText(label, data[i]),
        pointKey: _pointText(pointKey, data[i]),
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
      ? _xyPoints(data, mark.x, mark.y, mark.label, mark.pointKey)
      : _xyColorPoints(
          data,
          mark.x,
          mark.y,
          mark.colorBy!,
          mark.colorEncoding!,
          mark.label,
          mark.pointKey,
        ),
  color: mark.color,
  unit: mark.unit,
  isXOrdered: mark.isXOrdered,
  yAxisId: axis.id,
  yAxisConfig: axis,
  interpolation: mark.interpolation ?? _lineDefaults.interpolation,
  strokeWidth: mark.strokeWidth ?? _lineDefaults.strokeWidth,
  dashPattern: mark.dashPattern ?? _lineDefaults.dashPattern,
  showDataPointMarkers:
      mark.showDataPointMarkers ?? _lineDefaults.showDataPointMarkers,
  dataPointLabels: mark.dataPointLabels ?? _lineDefaults.dataPointLabels,
  tension: mark.tension ?? _lineDefaults.tension,
  dataPointMarkerRadius:
      mark.dataPointMarkerRadius ?? _lineDefaults.dataPointMarkerRadius,
  dataPointMarkerStyle:
      mark.dataPointMarkerStyle ?? _lineDefaults.dataPointMarkerStyle,
  dataPointMarkerBackground:
      mark.dataPointMarkerBackground ?? _lineDefaults.dataPointMarkerBackground,
  lineGlow: mark.lineGlow ?? _lineDefaults.lineGlow,
  inlineLabel: mark.inlineLabel ?? _lineDefaults.inlineLabel,
  pathAnimation: mark.pathAnimation ?? _lineDefaults.pathAnimation,
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
      ? _xyPoints(data, mark.x, mark.y, mark.label, mark.pointKey)
      : _xyColorPoints(
          data,
          mark.x,
          mark.y,
          mark.colorBy!,
          mark.colorEncoding!,
          mark.label,
          mark.pointKey,
        ),
  color: mark.color,
  unit: mark.unit,
  isXOrdered: mark.isXOrdered,
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
  tension: mark.tension ?? _areaDefaults.tension,
  dataPointMarkerRadius:
      mark.dataPointMarkerRadius ?? _areaDefaults.dataPointMarkerRadius,
  dataPointMarkerStyle:
      mark.dataPointMarkerStyle ?? _areaDefaults.dataPointMarkerStyle,
  dataPointMarkerBackground:
      mark.dataPointMarkerBackground ?? _areaDefaults.dataPointMarkerBackground,
  lineGlow: mark.lineGlow ?? _areaDefaults.lineGlow,
  inlineLabel: mark.inlineLabel ?? _areaDefaults.inlineLabel,
  pathAnimation: mark.pathAnimation ?? _areaDefaults.pathAnimation,
  // Nullable on the series, so these pass straight through: `?? _areaDefaults`
  // would be a no-op at best, and for a real gradient it would be wrong to read
  // as "unset means default" when unset IS the default.
  fillGradient: mark.fillGradient,
  aboveBaselineFillColor: mark.aboveBaselineFillColor,
  belowBaselineFillColor: mark.belowBaselineFillColor,
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
        ? _xyPoints(data, mark.x, mark.y, mark.label, mark.pointKey)
        : _barStyledPoints(
            data,
            mark.x,
            mark.y,
            mark.colorBy,
            mark.colorEncoding,
            mark.sizeBy,
            mark.sizeEncoding,
            mark.label,
            mark.pointKey,
          ),
    color: mark.color,
    unit: mark.unit,
    isXOrdered: mark.isXOrdered,
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
          label: _pointText(mark.label, row),
          pointKey: _pointText(mark.pointKey, row),
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
    unit: mark.unit,
    isXOrdered: mark.isXOrdered,
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

HeatmapChartSeries _lowerHeatmap<T>(
  HeatmapMark<T> mark,
  String id,
  YAxisConfig axis,
  XAxisConfig? xAxis,
  List<T> data,
) {
  final points = <HeatmapDataPoint>[];
  final identities = <HeatmapCellIdentity>{};
  for (var index = 0; index < data.length; index++) {
    final row = data[index];
    try {
      final x = mark.x(row).toDouble();
      final y = mark.y(row).toDouble();
      final pointKey = mark.pointKey?.call(row);
      final label = mark.label?.call(row);
      final point = mark.missing?.call(row) ?? false
          ? HeatmapDataPoint.missing(
              x: x,
              y: y,
              pointKey: pointKey,
              label: label,
            )
          : HeatmapDataPoint(
              x: x,
              y: y,
              value: mark.value(row).toDouble(),
              pointKey: pointKey,
              label: label,
            );
      if (!identities.add(point.identity)) {
        throw GrammarSpecException.invalidHeatmapRow(
          id,
          index,
          'cell identity ${point.identity} duplicates an earlier row.',
        );
      }
      points.add(point);
    } on GrammarSpecException {
      rethrow;
    } on ArgumentError catch (error) {
      throw GrammarSpecException.invalidHeatmapRow(
        id,
        index,
        '${error.name ?? 'value'} ${error.message}.',
      );
    }
  }

  final series = HeatmapChartSeries(
    id: id,
    name: mark.name,
    points: points,
    colorScale: mark.colorScale,
    yAxisId: axis.id,
    yAxisConfig: axis,
    unit: mark.unit,
    cellWidth: mark.cellWidth ?? _heatmapDefaults.cellWidth,
    cellHeight: mark.cellHeight ?? _heatmapDefaults.cellHeight,
    gapFraction: mark.gapFraction ?? _heatmapDefaults.gapFraction,
    borderColor: mark.borderColor ?? _heatmapDefaults.borderColor,
    borderWidth: mark.borderWidth ?? _heatmapDefaults.borderWidth,
    cornerRadius: mark.cornerRadius ?? _heatmapDefaults.cornerRadius,
    showCellLabels: mark.showCellLabels ?? _heatmapDefaults.showCellLabels,
    cellLabelColor: mark.cellLabelColor,
    cellLabelFontSize:
        mark.cellLabelFontSize ?? _heatmapDefaults.cellLabelFontSize,
    emptyValueStyle: mark.emptyValueStyle,
    valueFilter: mark.valueFilter,
  );
  try {
    series.validateCategoryCoordinates(
      xAxis: xAxis?.categoryAxis,
      yAxis: axis.categoryAxis,
    );
  } on ArgumentError catch (error) {
    throw GrammarSpecException.invalidHeatmapConfiguration(
      id,
      '${error.name ?? 'categoryAxis'} ${error.message}.',
    );
  }
  return series;
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
    unit: mark.unit,
    yAxisId: axis.id,
    yAxisConfig: axis,
  );
}

/// Materializes a range-area band.
///
/// Two row shapes are legal and one is not: both bounds present is an interval,
/// both absent is a gap, exactly one present is an authoring error. The
/// constructor's own `ArgumentError`s — a non-finite bound, `high < low`, an x
/// that did not increase — are translated to `invalidRangeAreaRow` so a grammar
/// author gets a grammar diagnostic naming the row rather than a raw model
/// error, exactly as `_lowerCandlestick` does. The series also refuses styling
/// arguments (tension, fillOpacity, a boundary style, ...); those name no row
/// and become `invalidRangeAreaStyle`.
RangeAreaChartSeries _lowerRangeArea<T>(
  RangeAreaMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) {
  final points = <RangeAreaDataPoint>[];
  for (var index = 0; index < data.length; index++) {
    final row = data[index];
    final x = mark.x(row).toDouble();
    final low = mark.low(row);
    final high = mark.high(row);
    if ((low == null) != (high == null)) {
      throw GrammarSpecException.incompleteRangeAreaInterval(id, index);
    }
    try {
      points.add(
        low == null
            ? RangeAreaDataPoint.gap(
                x: x,
                label: _pointText(mark.label, row),
                pointKey: _pointText(mark.pointKey, row),
              )
            : RangeAreaDataPoint(
                x: x,
                low: low.toDouble(),
                high: high!.toDouble(),
                label: _pointText(mark.label, row),
                pointKey: _pointText(mark.pointKey, row),
              ),
      );
    } on ArgumentError catch (error) {
      throw GrammarSpecException.invalidRangeAreaRow(
        id,
        index,
        '${error.name ?? 'value'} ${error.message}.',
      );
    }
  }
  try {
    return RangeAreaChartSeries(
      id: id,
      name: mark.name,
      points: points,
      color: mark.color,
      unit: mark.unit,
      yAxisId: axis.id,
      yAxisConfig: axis,
      interpolation: mark.interpolation ?? _rangeAreaDefaults.interpolation,
      tension: mark.tension ?? _rangeAreaDefaults.tension,
      fillOpacity: mark.fillOpacity ?? _rangeAreaDefaults.fillOpacity,
      borderMode: mark.borderMode ?? _rangeAreaDefaults.borderMode,
      upperBoundaryStyle:
          mark.upperBoundaryStyle ?? _rangeAreaDefaults.upperBoundaryStyle,
      lowerBoundaryStyle:
          mark.lowerBoundaryStyle ?? _rangeAreaDefaults.lowerBoundaryStyle,
      connectGaps: mark.connectGaps ?? _rangeAreaDefaults.connectGaps,
      showBoundaryMarkers:
          mark.showBoundaryMarkers ?? _rangeAreaDefaults.showBoundaryMarkers,
      markerRadius: mark.markerRadius ?? _rangeAreaDefaults.markerRadius,
      labelConfig: mark.labelConfig ?? _rangeAreaDefaults.labelConfig,
      hitTestMode: mark.hitTestMode ?? _rangeAreaDefaults.hitTestMode,
    );
  } on ArgumentError catch (error) {
    // The series constructor re-validates the WHOLE band, so two unrelated
    // families of failure arrive here and `ArgumentError.name` is what tells
    // them apart.
    //
    // Row rules — the strictly increasing x rule lives on the series, not on
    // the point — name the offender `points[3]` / `points[3].x`, so the row
    // number is recovered from the name and the diagnostic still names a row.
    //
    // Styling rules (tension, fillOpacity, markerRadius, the fill gradient,
    // either boundary style, the path animation) name a PARAMETER instead.
    // Those say nothing about any row, so they get their own diagnostic:
    // inventing a row index for them would name a row that is perfectly valid
    // and a category of failure that did not happen. A named diagnostic rather
    // than a rethrown ArgumentError, because a grammar author should never see
    // a raw model error escape lowering — the same trade `_guardPolar` makes.
    final name = error.name ?? '';
    final match = RegExp(r'points\[(\d+)\]').firstMatch(name);
    if (match == null) {
      throw GrammarSpecException.invalidRangeAreaStyle(
        id,
        _authorityDetail(error),
      );
    }
    throw GrammarSpecException.invalidRangeAreaRow(
      id,
      int.parse(match.group(1)!),
      '$name ${error.message}.',
    );
  }
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

/// Lowers a RADIAL spec: no Cartesian marks, no Cartesian axis/grid option.
/// The whole dataset maps to one radial series (or, for a ring channel, one
/// per ring). Exactly one radial geom is the rule for pie/donut; the polar
/// family relaxes it — N [PolarMark]s lower to N `PolarColumnChartSeries`
/// sharing the spec-level [PlotSpec.polar] composition — which they must be
/// ABLE to share: the composition contract
/// ([PolarColumnComposition.validate], the same one the render pipeline and the
/// artifact hydrator enforce) is checked here so a chain fails with a named
/// diagnostic instead of a raw `ArgumentError` at widget mount. The concentric
/// donut family is held to the same rule against
/// [ConcentricDonutLayoutCalculator]. Validation order is deterministic and
/// matches the Cartesian contract: every data-INDEPENDENT structural check runs
/// before the emptyData guard, so BravenPlot swallows ONLY an otherwise
/// well-formed empty spec.
LoweredPlot _lowerRadial<T>(PlotSpec<T> spec, List<String> markIds) {
  final radialIndices = <int>[
    for (var index = 0; index < spec.marks.length; index++)
      if (spec.marks[index] is RadialMark<T>) index,
  ];
  // Multiple radial marks are legal ONLY when every one is a polar column:
  // polar composition (layered/grouped/stacked) genuinely spans series, while
  // two pies or a pie plus a donut have no shared coordinate meaning.
  final allPolar = radialIndices.every(
    (index) => spec.marks[index] is PolarMark<T>,
  );
  if (radialIndices.length > 1 && !allPolar) {
    throw GrammarSpecException.multipleRadialGeoms(<String>[
      for (final index in radialIndices) markIds[index],
    ]);
  }
  final markIndex = radialIndices.first;
  // Any non-radial mark in the spec mixes coordinate systems. Counting rather
  // than comparing against `1` keeps the multi-polar spec legal while a polar
  // plus a line (or reference) mark still fails exactly as before.
  if (spec.marks.length > radialIndices.length) {
    final radialSet = radialIndices.toSet();
    throw GrammarSpecException.mixedCoordinateSystems(
      markIds[markIndex],
      <String>[
        for (var index = 0; index < spec.marks.length; index++)
          if (!radialSet.contains(index)) markIds[index],
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

  // A plot-level PolarChartConfig only has meaning over polar columns; on a
  // pie/donut spec it would be silently discarded, so it is refused by name.
  // (The Cartesian case is caught earlier, in `_lower`.)
  if (spec.polar != null && !allPolar) {
    throw GrammarSpecException.polarConfigOnNonPolarSpec(markIds[markIndex]);
  }

  // A ConcentricDonutConfig owns the shared center through its centerContent,
  // and `center` is the shorthand for that same slot: honoring one would have
  // to discard the other silently, so the ambiguity is refused by name.
  if (mark is DonutMark<T> && mark.concentric != null && mark.center != null) {
    throw GrammarSpecException.conflictingConcentricCenter(markId);
  }

  if (mark is DonutMark<T> && mark.concentric != null) {
    // Without a ring channel there is no composition for the config to
    // describe: the ring gap, order, weights, radii and legend mode are all
    // inert, the render path never reads it (`braven_chart_plus` stamps
    // `concentricDonutConfig` only for MORE THAN ONE donut series), and the
    // capture path drops it — so a chain that set it would come back from the
    // source generator without it. Refused by name, as `.polarConfig(...)` on
    // a non-polar spec is.
    if (mark.ring == null) {
      throw GrammarSpecException.concentricConfigOnRinglessDonut(markId);
    }
    // The DATA-INDEPENDENT half of the concentric contract: pane radii, ring
    // gap, ring-weight magnitudes and the shared center are decidable from the
    // config alone, so they are checked ABOVE the emptyData guard — a chain
    // must not lower clean over an empty (or momentarily single-ring) dataset
    // and then throw a raw ArgumentError out of the layout calculator once the
    // real rows arrive.
    _guardConcentric(
      () => ConcentricDonutLayoutCalculator.validateConfig(mark.concentric!),
    );
  }

  // The same refusal, for the same reason, for the per-ring override map. Its
  // key-existence half is checked against the ACTUAL ring keys down in
  // [_lowerConcentricRings] — but that function only runs for a mark WITH a
  // ring channel, so the ring-less shape would escape every check and drop the
  // whole map. That is the most inert form of the mistake, not the least: with
  // no rings at all there is nothing any entry could ever apply to.
  //
  // Decidable from the mark's shape alone, so it sits here, above the emptyData
  // guard, with the other shape checks. An EMPTY map is exempt: it carries no
  // override, so it is the same no-op here that it is on the ringed path, and
  // refusing it would fork the two paths apart over a map that means nothing
  // either way.
  if (mark is DonutMark<T> &&
      mark.ring == null &&
      (mark.dataLabelsByRing?.isNotEmpty ?? false)) {
    throw GrammarSpecException.perRingOverrideOnRinglessDonut(
      markId,
      'dataLabelsByRing',
      mark.dataLabelsByRing!.keys,
    );
  }

  // …and for the ring-ID map, for the identical reason: with no ring channel
  // there are no ring series for it to name, so every entry would be dropped.
  // The remedy differs — a ring-less donut's series id is the MARK id — so the
  // diagnostic names `id:` rather than `dataLabels:`.
  if (mark is DonutMark<T> &&
      mark.ring == null &&
      (mark.ringIds?.isNotEmpty ?? false)) {
    throw GrammarSpecException.perRingOverrideOnRinglessDonut(
      markId,
      'ringIds',
      mark.ringIds!.keys,
      singleDonutParameter: 'id:',
    );
  }

  // The polar composition contract that is decidable from the spec's SHAPE.
  if (allPolar) {
    _validatePolarMarkComposition<T>(spec, radialIndices, markIds);
  }

  // Data-dependent checks live below the emptyData guard.
  if (spec.data.isEmpty) throw GrammarSpecException.emptyData();

  // Every radial mark is checked, not just the first: a multi-polar spec whose
  // second mark labels nothing would otherwise draw an unlabelled band.
  for (final index in radialIndices) {
    final radialMark = spec.marks[index] as RadialMark<T>;
    final hasVisibleCategory = spec.data.any(
      (row) => radialMark.category(row).toString().trim().isNotEmpty,
    );
    if (!hasVisibleCategory) {
      throw GrammarSpecException.emptyRadialCategories(markIds[index]);
    }
  }

  final series = <ChartSeries>[];
  ConcentricDonutConfig? concentric;
  PolarChartConfig? polar;

  if (allPolar) {
    final columns = <PolarColumnChartSeries>[
      for (final index in radialIndices)
        _lowerPolar<T>(
          spec.marks[index] as PolarMark<T>,
          markIds[index],
          spec.data,
        ),
    ];
    series.addAll(columns);
    polar = spec.polar ?? const PolarChartConfig();
    // The DATA-DEPENDENT half of the composition contract (diverging category
    // domains, and — once the advanced per-series fields land — presets and
    // intervals). Delegating to the same validator the render pipeline and the
    // artifact hydrator run is what keeps the grammar from drifting away from
    // the contract it lowers onto: without it a chain lowers clean and then
    // throws a raw ArgumentError at widget mount.
    //
    // The "stacked composition cannot carry intervals" rule stays HERE, below
    // the emptyData guard, and that is deliberate — do not hoist it into
    // [_validatePolarMarkComposition] alongside the config and preset checks.
    // `PolarColumnChartSeries.hasIntervals` is a property of the LOWERED series,
    // not of the mark: a mark may declare both interval accessors and still
    // produce ZERO intervals, because `_lowerPolar` only records a category's
    // interval when BOTH bounds come back non-null for that row. So a stacked
    // spec whose interval accessors return null for every row composes cleanly
    // and must lower, and only the materialized series can tell us which case we
    // are in. What IS decidable from the mark — that exactly one of the two
    // bounds was supplied — is already hoisted, as `incompletePolarInterval`.
    _guardPolar(() => PolarColumnComposition.validate(columns, config: polar));
  } else if (mark is PieMark<T>) {
    series.add(_lowerPie<T>(mark, markId, spec.data));
  } else if (mark is DonutMark<T>) {
    // Center precedence: an explicit ConcentricDonutConfig is authoritative,
    // including its centerContent; `center` is the shorthand honored only when
    // no config was supplied (setting both is refused above). Keeping the two
    // sources in one local is what makes every donut path agree.
    final center = mark.concentric?.centerContent ?? mark.center;
    if (mark.ring == null) {
      // `concentric` on a ring-less donut is refused above, so `center` here is
      // exactly the mark's own shorthand and no config is produced: the
      // family's `LoweredPlot.concentricDonutConfig` stays null, which is what
      // lets the source emitter keep treating a non-null config as the
      // authoritative "this is a concentric composition" discriminator.
      series.add(_lowerDonut<T>(mark, markId, spec.data, center));
    } else {
      final rings = _lowerConcentricRings<T>(mark, markId, spec.data);
      if (rings.length == 1) {
        // A single-value ring collapses to a plain donut. The render path only
        // reads `ConcentricDonutConfig.centerContent` when more than one donut
        // series is present, so the lone ring must carry the mark's center on
        // itself — exactly like the ring-less donut path — or the center is
        // silently hidden.
        //
        // The center is the ONLY thing this branch overrides. Everything else,
        // per-ring data labels included, is already resolved for this ring key
        // by [_lowerConcentricRings]; re-stating any of it here would fork the
        // collapse away from the composition it collapsed from.
        series.add(
          rings.single.copyWith(
            centerContent: center ?? DonutCenterContent.hidden,
          ),
        );
        concentric = mark.concentric ?? const ConcentricDonutConfig();
      } else {
        series.addAll(rings);
        concentric =
            mark.concentric ??
            (mark.center == null
                ? const ConcentricDonutConfig()
                : ConcentricDonutConfig(centerContent: mark.center!));
        // The DATA-DEPENDENT half of the concentric contract, delegated to the
        // same validator the render pipeline runs. It is scoped to a real
        // composition (>1 ring) because that is exactly the shape the render
        // pipeline validates: below two donut series the widget nulls the
        // config and lays a plain donut out, so refusing here would reject a
        // chart that renders. A ring weight naming no ring — the natural
        // mistake, because the rings are ided `<markId>-<ringKey>` unless
        // `ringIds` names them — is caught here instead of as a raw
        // ArgumentError at widget mount. WHICH scheme ided them is passed
        // along: the diagnostic's remedy clause has to prescribe the one in
        // force, not the one that just failed.
        _guardConcentric(
          () => ConcentricDonutLayoutCalculator.validateSeries(
            rings,
            concentric!,
          ),
          ringIds: <String>[for (final ring in rings) ring.id],
          explicitRingIds: mark.ringIds?.isNotEmpty ?? false,
        );
      }
    }
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

/// One authority `ArgumentError` rendered as a diagnostic detail sentence.
///
/// Leads with the error's `name` — the FIELD that failed, e.g.
/// "pane.innerRadiusFactor" — because the named diagnostic REPLACES the raw
/// error rather than accompanying it. A `PolarChartConfig` range-checks eight
/// fields and a `ConcentricDonutConfig` three, so "Value must be in [0, 1)" on
/// its own would make the grammar's diagnostic strictly less actionable than
/// the error it hides. An `ArgumentError` raised without a name still renders
/// (the authority's sentence alone), so this cannot regress into "null: ".
String _authorityDetail(ArgumentError error) {
  final field = error.name == null ? '' : '${error.name}: ';
  return error.invalidValue == null
      ? '$field${error.message}.'
      : '$field${error.message} ("${error.invalidValue}").';
}

/// Runs one concentric-donut contract check and renames its failure.
///
/// [ConcentricDonutLayoutCalculator] is the authority — the same validator the
/// render pipeline runs before it allocates ring bands — so the grammar
/// delegates to it and translates the raw `ArgumentError` into a named
/// diagnostic, rather than restating (and eventually contradicting) its rules.
/// [ringIds] is supplied for the series half, where naming the real ring ids is
/// what makes a misdirected `ringWeights` key actionable, and
/// [explicitRingIds] says which scheme produced them so the remedy clause
/// prescribes the scheme this composition actually uses.
void _guardConcentric(
  void Function() check, {
  Iterable<String> ringIds = const <String>[],
  bool explicitRingIds = false,
}) {
  try {
    check();
  } on ArgumentError catch (error) {
    throw GrammarSpecException.invalidConcentricComposition(
      _authorityDetail(error),
      ringIds: ringIds,
      explicitRingIds: explicitRingIds,
    );
  }
}

/// Runs one polar contract check and renames its failure.
///
/// The twin of [_guardConcentric], for the polar half. [PolarChartConfig] (for
/// the config's own rules) and [PolarColumnComposition] (for the lowered
/// series') are the authorities — the same validators `BravenChartPlus` runs
/// before it lays a polar pane out, and the artifact hydrator runs on load — so
/// the grammar delegates to them and translates the raw `ArgumentError` into a
/// named diagnostic, rather than restating (and eventually contradicting) their
/// rules.
void _guardPolar(void Function() check) {
  try {
    check();
  } on ArgumentError catch (error) {
    throw GrammarSpecException.invalidPolarComposition(_authorityDetail(error));
  }
}

/// The DATA-INDEPENDENT half of the polar composition contract.
///
/// [PolarColumnComposition.validate] is the authority, but it needs the lowered
/// series — which need rows. The facts below are decidable from the spec's
/// SHAPE alone — the `.polarConfig(...)` object's own self-consistency, a mark's
/// `unit`, how many polar marks the plot holds against the composition mode the
/// config selects, whether a mark set exactly one interval bound, and a mark's
/// `preset` — so they are checked here, ABOVE the emptyData guard, exactly like
/// every other structural check. That is what stops an authoring mistake from
/// hiding behind a momentarily-empty dataset and only surfacing — as a raw
/// `ArgumentError` from the render pipeline — once real rows arrive.
///
/// Order within this function is deliberate and matches the order the checks
/// occupied when they were spread across lowering: config, then unit, then
/// composition mode, then intervals, then preset. Reshuffling would change which
/// diagnostic a spec with several mistakes reports first.
void _validatePolarMarkComposition<T>(
  PlotSpec<T> spec,
  List<int> radialIndices,
  List<String> markIds,
) {
  // The config is the pane every mark is measured in, so its own contract is
  // settled before the marks are compared against each other. Every rule
  // `PolarChartConfig.validate()` enforces — pane geometry, radial-axis bounds,
  // the grouped sub-band padding, per-threshold finiteness and dash-pair parity,
  // and the stacked zero-baseline — reads the config and nothing else, so it
  // belongs above the emptyData guard for the same reason the concentric
  // config check does: `BravenChartPlus` runs this very validator at mount, and
  // a chain must not lower clean over an empty dataset only to throw a raw
  // ArgumentError there once the real rows arrive.
  if (spec.polar case final config?) {
    _guardPolar(config.validate);
  }

  final firstIndex = radialIndices.first;
  final firstUnit = _normalizedPolarUnit(
    (spec.marks[firstIndex] as PolarMark<T>).unit,
  );
  for (final index in radialIndices.skip(1)) {
    final unit = _normalizedPolarUnit((spec.marks[index] as PolarMark<T>).unit);
    if (unit != firstUnit) {
      throw GrammarSpecException.invalidPolarComposition(
        'The mark "${markIds[index]}" reads in ${_polarUnitLabel(unit)} while '
        '"${markIds[firstIndex]}" reads in ${_polarUnitLabel(firstUnit)}; one '
        'shared radial axis cannot measure both. Give every geomPolar the same '
        'unit, or split them into separate charts.',
      );
    }
  }

  final mode = spec.polar?.composition.mode;
  if ((mode == PolarColumnCompositionMode.grouped ||
          mode == PolarColumnCompositionMode.stacked) &&
      radialIndices.length < 2) {
    throw GrammarSpecException.invalidPolarComposition(
      '.polarConfig(...) selects ${mode!.name} composition, which divides every '
      'category between at least two series, but this plot has '
      '${radialIndices.length} geomPolar mark. Add another geomPolar, or drop '
      'the composition mode to leave the columns layered.',
    );
  }

  // An interval needs BOTH endpoints. Which of the two accessors is null is a
  // property of the mark, not of any row, so the half-specified channel is
  // refused here rather than during materialization — a bound alone cannot be
  // drawn no matter what rows arrive. Checked over every polar mark in spec
  // order, which is the order `_lowerPolar` would have reached them in.
  for (final index in radialIndices) {
    final mark = spec.marks[index] as PolarMark<T>;
    if ((mark.intervalLow == null) != (mark.intervalHigh == null)) {
      throw GrammarSpecException.incompletePolarInterval(markIds[index]);
    }
  }

  // A rose series divides the circle into equal angles and encodes value as
  // AREA; a standard series encodes it as radius. One pane cannot draw both.
  // `PolarColumnComposition.validate` is the authority and still re-checks the
  // lowered series below, but it needs rows to have series at all — so the
  // rule is restated here, over the marks' own `preset` fields, in the
  // authority's exact words. `test/unit/grammar/plot_lowering_radial_test.dart`
  // pins this message to the one the authority renders, so the restatement
  // cannot drift into a second sentence for the same mistake.
  //
  // Compared as "is it rose", not by raw enum identity, because that is the
  // only distinction `_lowerPolar` makes when it picks a constructor: should
  // the enum ever gain a third member that still lowers to `standard`, this
  // check stays LAX (the authority below catches any real clash a moment
  // later) instead of refusing a pair that would have lowered compatibly.
  final firstIsRose = _isRosePolar<T>(spec.marks[firstIndex]);
  for (final index in radialIndices.skip(1)) {
    if (_isRosePolar<T>(spec.marks[index]) != firstIsRose) {
      throw GrammarSpecException.invalidPolarComposition(
        'Multiple Polar Column series must use the same preset '
        '("${markIds[index]}").',
      );
    }
  }
}

/// Whether [mark] lowers to the Rose constructor.
///
/// This is the ONLY distinction `_lowerPolar` draws from `PolarMark.preset`, so
/// comparing marks through it — rather than by raw enum identity — is what keeps
/// the shape check in step with what the marks actually lower to.
bool _isRosePolar<T>(Mark<T> mark) =>
    (mark as PolarMark<T>).preset == PolarColumnPreset.rose;

/// Units compare the way [PolarColumnComposition] compares them: trimmed, with
/// "no unit" and an all-whitespace unit treated as the same thing.
String _normalizedPolarUnit(String? unit) => (unit ?? '').trim();

String _polarUnitLabel(String normalized) =>
    normalized.isEmpty ? 'no unit' : '"$normalized"';

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

/// Builds the per-category slice-color map for a pie/donut geom.
///
/// A null return SKIPS the category, leaving it on the series color — exactly
/// what an unset accessor does for every row, so an unset accessor and an
/// all-null accessor produce the same series. The families' `fromMap` builds
/// the GENERAL `PointStyle(color:, size:)`, so a color and a radius on the same
/// category compose rather than one displacing the other.
Map<String, Color> _sliceColors<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, Color?> sliceColor,
) {
  final result = <String, Color>{};
  for (final row in data) {
    final color = sliceColor(row);
    if (color != null) result[category(row).toString()] = color;
  }
  return result;
}

PieChartSeries _lowerPie<T>(PieMark<T> mark, String id, List<T> data) =>
    PieChartSeries.fromMap(
      id: id,
      name: mark.name,
      color: mark.color,
      unit: mark.unit,
      values: _radialValues(data, mark.category, mark.value),
      sliceColors: mark.sliceColor == null
          ? const <String, Color>{}
          : _sliceColors(data, mark.category, mark.sliceColor!),
      radiusValues: mark.radius == null
          ? const <String, num>{}
          : _radiusValues(data, mark.category, mark.radius!),
      sliceRadiusConfig: mark.sliceRadiusConfig,
      sliceGroupingConfig: mark.sliceGroupingConfig,
      pieStyle: mark.style ?? const PieChartStyle(),
      selectionStyle: mark.selectionStyle ?? const RadialSelectionStyle(),
      dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
    );

/// Builds the single (ring-less) donut. [center] is the center resolved by the
/// caller's precedence rule (`concentric.centerContent` over `mark.center`),
/// so this function never reads `mark.center` itself.
DonutChartSeries _lowerDonut<T>(
  DonutMark<T> mark,
  String id,
  List<T> data,
  DonutCenterContent? center,
) => DonutChartSeries.fromMap(
  id: id,
  name: mark.name,
  color: mark.color,
  unit: mark.unit,
  values: _radialValues(data, mark.category, mark.value),
  sliceColors: mark.sliceColor == null
      ? const <String, Color>{}
      : _sliceColors(data, mark.category, mark.sliceColor!),
  radiusValues: mark.radius == null
      ? const <String, num>{}
      : _radiusValues(data, mark.category, mark.radius!),
  sliceRadiusConfig: mark.sliceRadiusConfig,
  sliceGroupingConfig: mark.sliceGroupingConfig,
  donutStyle: mark.style ?? const DonutChartStyle(),
  selectionStyle: mark.selectionStyle ?? const RadialSelectionStyle(),
  centerContent: center ?? DonutCenterContent.hidden,
  dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
);

/// Partitions [data] by the donut mark's ring accessor (first-seen order) and
/// builds one `DonutChartSeries` per ring. The shared center is carried by the
/// composition's `ConcentricDonutConfig`, so each ring donut's own center is
/// hidden.
///
/// Per-ring data labels resolve here, which is what makes the single-ring
/// COLLAPSE honor an override too: `_lowerRadial` builds that lone donut from
/// this function's output and only `copyWith`s the center onto it, so the
/// resolution below is the one authority for both concentric paths. Keep it
/// that way — resolving at the call site instead would leave the collapse
/// branch on the base config.
List<DonutChartSeries> _lowerConcentricRings<T>(
  DonutMark<T> mark,
  String markId,
  List<T> data,
) {
  final order = <String>[];
  final buckets = <String, List<T>>{};
  for (final row in data) {
    final key = mark.ring!(row).toString();
    buckets
        .putIfAbsent(key, () {
          order.add(key);
          return <T>[];
        })
        .add(row);
  }
  // An override keyed to a ring this data never produces is INERT: it applies
  // to nothing and reports nothing, so the typo survives into the rendered
  // chart. It is checked against the ACTUAL ring keys, which is why it lives
  // here — below the emptyData guard — instead of with the shape-decidable
  // checks in [_lowerRadial].
  final unknownRings = <String>[
    for (final key in mark.dataLabelsByRing?.keys ?? const <String>[])
      if (!buckets.containsKey(key)) key,
  ];
  if (unknownRings.isNotEmpty) {
    throw GrammarSpecException.unknownRingKey(
      markId,
      'dataLabelsByRing',
      unknownRings,
      order,
    );
  }
  // The same check for the ring-ID map, which is keyed the same way and goes
  // just as silently inert.
  final unknownIdRings = <String>[
    for (final key in mark.ringIds?.keys ?? const <String>[])
      if (!buckets.containsKey(key)) key,
  ];
  if (unknownIdRings.isNotEmpty) {
    throw GrammarSpecException.unknownRingKey(
      markId,
      'ringIds',
      unknownIdRings,
      order,
    );
  }
  // ALL OR NOTHING. Naming half the rings leaves the rest on the generated
  // '<markId>-<ringKey>' id, so one composition would carry two id schemes and
  // `ringWeights` — keyed by the RESULTING id — would take a different scheme
  // per ring. Checked AFTER the unknown-key guard so a typo is reported as the
  // typo it is rather than as the hole it leaves.
  if (mark.ringIds?.isNotEmpty ?? false) {
    final unnamed = <String>[
      for (final key in order)
        if (!mark.ringIds!.containsKey(key)) key,
    ];
    if (unnamed.isNotEmpty) {
      throw GrammarSpecException.partialRingIds(
        markId,
        mark.ringIds!.keys,
        unnamed,
      );
    }
  }
  return <DonutChartSeries>[
    for (final key in order)
      DonutChartSeries.fromMap(
        // The explicit id when `ringIds` names this ring, else the generated
        // '<markId>-<ringKey>' that is the family's convention. Whichever one
        // wins, THIS is the id `ConcentricDonutConfig.ringWeights` keys by —
        // the validator below is handed these very ids.
        id: mark.ringIds?[key] ?? '$markId-$key',
        name: key,
        unit: mark.unit,
        values: _radialValues(buckets[key]!, mark.category, mark.value),
        sliceColors: mark.sliceColor == null
            ? const <String, Color>{}
            : _sliceColors(buckets[key]!, mark.category, mark.sliceColor!),
        radiusValues: mark.radius == null
            ? const <String, num>{}
            : _radiusValues(buckets[key]!, mark.category, mark.radius!),
        sliceRadiusConfig: mark.sliceRadiusConfig,
        sliceGroupingConfig: mark.sliceGroupingConfig,
        donutStyle: mark.style ?? const DonutChartStyle(),
        selectionStyle: mark.selectionStyle ?? const RadialSelectionStyle(),
        centerContent: DonutCenterContent.hidden,
        dataLabels:
            mark.dataLabelsByRing?[key] ??
            mark.dataLabels ??
            const PieDataLabelConfig(),
      ),
  ];
}

/// Materializes one polar mark.
///
/// Every DATA-INDEPENDENT check this needed — notably the half-specified
/// interval, which is decidable from the accessors' nullity alone — lives in
/// [_validatePolarMarkComposition], above the emptyData guard. So the
/// `intervalHigh!` below is safe: a mark that reached here has both bounds or
/// neither.
PolarColumnChartSeries _lowerPolar<T>(
  PolarMark<T> mark,
  String id,
  List<T> data,
) {
  // `_radialValues` iterates `data` in order and rejects duplicate categories,
  // so the per-category maps built below share its key order — which is what
  // `PolarColumnChartSeries._fromMap` aligns `targetValues` and the interval
  // bound lists to.
  final values = _radialValues(data, mark.category, mark.value);
  final columnColors = <String, Color>{};
  final targets = <String, num?>{};
  final intervals = <String, PolarColumnInterval>{};
  for (final row in data) {
    final category = mark.category(row).toString();
    if (mark.columnColor != null) {
      final color = mark.columnColor!(row);
      // A null color leaves the category on the series color, exactly as an
      // unset accessor does for every row.
      if (color != null) columnColors[category] = color;
    }
    if (mark.target != null) {
      // Null is meaningful: the category keeps its point but loses its marker.
      targets[category] = mark.target!(row);
    }
    if (mark.intervalLow != null) {
      final lower = mark.intervalLow!(row);
      final upper = mark.intervalHigh!(row);
      if (lower != null && upper != null) {
        intervals[category] = PolarColumnInterval(
          lower: lower.toDouble(),
          upper: upper.toDouble(),
        );
      }
    }
  }

  final build = _isRosePolar<T>(mark)
      ? PolarColumnChartSeries.rose
      : PolarColumnChartSeries.fromMap;
  return build(
    id: id,
    name: mark.name,
    color: mark.color,
    unit: mark.unit,
    values: values,
    columnColors: columnColors,
    polarStyle: mark.style ?? const PolarColumnStyle(),
    selectionStyle: mark.selectionStyle ?? const RadialSelectionStyle(),
    targets: targets,
    targetMarkerStyle:
        mark.targetMarkerStyle ?? const PolarColumnTargetMarkerStyle(),
    intervals: intervals,
    intervalStyle: mark.intervalStyle ?? const PolarColumnIntervalStyle(),
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
  FieldAccessor<T, String?>? label,
  FieldAccessor<T, String?>? pointKey,
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
        label: _pointText(label, data[i]),
        pointKey: _pointText(pointKey, data[i]),
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
