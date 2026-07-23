// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Fail-fast diagnostics for the grammar spec layer.
///
/// The tone matches `ChartConfigBuilder`: a spec that cannot be honored raises
/// immediately, with a sentence that names what was wrong and what to do about
/// it. Nothing is silently dropped, defaulted, or rendered differently from
/// what was asked for. The difference from `ChartConfigBuilder` is the CODE:
/// grammar specs are written in Dart by a human or a facade, so a machine
/// readable code lets the facade (Task 12) and the showcase surface the same
/// failures without string matching.
library;

/// The complete set of grammar diagnostics.
enum GrammarDiagnosticCode {
  /// The spec declared no marks, so there is no geometry to draw.
  emptyMarks,

  /// The spec declared no rows, so no mark can materialize a point.
  emptyData,

  /// Two marks resolved to the same id.
  duplicateMarkId,

  /// A [TrendMark] named a source that is not a geometry mark in this spec.
  unknownTrendSource,

  /// A moving-average trend was declared without a positive window size.
  invalidTrendWindow,

  /// A mark bound to a Y-axis id that no declared axis carries.
  unknownAxisId,

  /// Two declared Y axes resolved to the same id.
  duplicateAxisId,

  /// A declared Y axis that no mark measures against.
  unboundAxis,

  /// A channel was supplied without the encoding it needs to resolve a scale.
  missingChannelEncoding,

  /// An encoding was supplied with no channel to drive it, so it would be inert.
  orphanChannelEncoding,

  /// A channel asked for a scale the render pipeline does not implement.
  unsupportedChannelScale,

  /// `transposed: true` was combined with a geometry that cannot transpose.
  unsupportedTransposition,

  /// A candlestick row violated the OHLC invariants or ordering.
  invalidCandlestickRow,

  /// A facade geom was built without an x or y encoding to inherit.
  ///
  /// Raised by the chained `BravenChart` facade, never by `spec.lower()` — a
  /// [PlotSpec] cannot express a mark with a missing accessor.
  missingEncoding,

  /// A faceted spec was handed to a single-panel path (`PlotSpec.lower()` /
  /// `BravenChart.build()`). Render it with `BravenChart.buildFaceted()`.
  facetedSpecNotLowerable,

  /// `buildFaceted()` was called on a spec that declared no `.facet(...)`.
  notFaceted,

  /// Faceting found no rows to partition, so there is no panel to draw.
  emptyFacetValues,

  /// Faceting produced more than the panel cap allows.
  facetPanelCapExceeded,

  /// A facet declared a non-positive `columns` count, which cannot lay out a
  /// grid (the panel-layout loop would never advance).
  facetColumnsNotPositive,

  /// A multi-y-axis spec was faceted under a shared-Y scale mode, which v1
  /// cannot honor without distorting the declared axes.
  facetMultiAxisSharedY,

  /// A radial geom was combined with a Cartesian (or reference) mark.
  mixedCoordinateSystems,

  /// A spec declared more than one radial geom.
  multipleRadialGeoms,

  /// A Cartesian axis/grid option (grid, xAxis, yAxis, transposed) was set on
  /// a radial spec.
  axisOptionOnRadialSpec,

  /// A radial geom produced no category with a visible label.
  emptyRadialCategories,

  /// A radial spec also requested faceting, which radial does not yet support.
  facetedRadialUnsupported,
}

/// Raised when a [PlotSpec] cannot be lowered onto the config surface.
final class GrammarSpecException implements Exception {
  /// Creates a diagnostic with an explicit [code] and [message].
  const GrammarSpecException(this.code, this.message);

  /// The spec declared no marks.
  factory GrammarSpecException.emptyMarks() => const GrammarSpecException(
    GrammarDiagnosticCode.emptyMarks,
    'A plot needs at least one mark. Add a geometry such as '
    'LineMark(x: ..., y: ...) to PlotSpec.marks.',
  );

  /// The spec declared no rows.
  factory GrammarSpecException.emptyData() => const GrammarSpecException(
    GrammarDiagnosticCode.emptyData,
    'A plot needs at least one row. Pass the rows the mark accessors read '
    'to PlotSpec.data, or render an empty-state widget instead.',
  );

  /// Two marks resolved to the same id.
  factory GrammarSpecException.duplicateMarkId(String id) =>
      GrammarSpecException(
        GrammarDiagnosticCode.duplicateMarkId,
        'Two marks resolved to the id "$id". A mark id becomes the series id '
        'that axes and annotations bind to, so it must be unique.',
      );

  /// A trend named a source that is not a geometry mark.
  factory GrammarSpecException.unknownTrendSource(
    String sourceMarkId,
    Iterable<String> known,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.unknownTrendSource,
    'TrendMark(sourceMarkId: "$sourceMarkId") does not name a geometry mark '
    'in this plot. Known geometry marks: ${_list(known)}. A trend cannot be '
    'computed over another trend.',
  );

  /// A moving-average trend was declared without a positive window size.
  factory GrammarSpecException.invalidTrendWindow(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.invalidTrendWindow,
        'The trend "$markId" is a moving average, so it needs a positive '
        'windowSize.',
      );

  /// A mark bound to an unknown axis id.
  factory GrammarSpecException.unknownAxisId(
    String markId,
    String axisId,
    Iterable<String> known,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.unknownAxisId,
    'The mark "$markId" binds to yAxisId "$axisId", which no axis in '
    'PlotSpec.yAxes carries. Declared axes: ${_list(known)}.',
  );

  /// Two declared axes resolved to the same id.
  factory GrammarSpecException.duplicateAxisId(String axisId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.duplicateAxisId,
        'Two entries in PlotSpec.yAxes resolved to the id "$axisId". Axis ids '
        'are the join key marks bind to, so they must be unique.',
      );

  /// A declared axis that no mark measures against.
  factory GrammarSpecException.unboundAxis(String axisId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.unboundAxis,
        'No mark measures against the axis "$axisId". An axis derives its '
        'scale from the series bound to it, so an unbound axis would never '
        'reach the chart. Bind a mark with yAxisId: "$axisId", or remove the '
        'axis.',
      );

  /// A channel was supplied without the encoding it needs.
  factory GrammarSpecException.missingChannelEncoding(
    String markId,
    String channel,
    String remedy,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.missingChannelEncoding,
    'The mark "$markId" encodes $channel but supplied no scale for it. '
    '$remedy',
  );

  /// An encoding was supplied with no channel to drive it.
  factory GrammarSpecException.orphanChannelEncoding(
    String markId,
    String encoding,
    String channel,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.orphanChannelEncoding,
    'The mark "$markId" supplied $encoding but no $channel channel to drive '
    'it, so the encoding would be silently inert. Pass $channel: '
    'Channel((row) => ...) to activate it, or drop the $encoding. (The '
    'grammar layer never keeps a dropped or defaulted binding.)',
  );

  /// A channel asked for a scale the render pipeline does not implement.
  factory GrammarSpecException.unsupportedChannelScale(
    String markId,
    String channel,
    String requested,
    String native,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.unsupportedChannelScale,
    'The mark "$markId" asked for a $requested scale on its $channel '
    'channel. That channel renders on a $native scale only; leave '
    'Channel.scale null to select it.',
  );

  /// `transposed: true` combined with a geometry that cannot transpose.
  factory GrammarSpecException.unsupportedTransposition(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.unsupportedTransposition,
        'PlotSpec.transposed is true, but "$markId" is not a BarMark. '
        'Transposition is implemented by horizontal bar geometry, which '
        'transposes the whole plane; a transposed plot can therefore contain '
        'bar marks only.',
      );

  /// A candlestick row violated the OHLC invariants or ordering.
  factory GrammarSpecException.invalidCandlestickRow(
    String markId,
    int rowIndex,
    String reason,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.invalidCandlestickRow,
    'Row $rowIndex of the candlestick mark "$markId" is not a valid candle: '
    '$reason',
  );

  /// A facade geom was built without an x or y encoding to inherit.
  factory GrammarSpecException.missingEncoding(String verb, String channel) =>
      GrammarSpecException(
        GrammarDiagnosticCode.missingEncoding,
        '$verb() has no $channel encoding. Pass $channel: (row) => ..., or '
        'set a chart-wide default with .$channel(...) before this geom.',
      );

  /// A faceted spec reached a single-panel path.
  factory GrammarSpecException.facetedSpecNotLowerable() =>
      const GrammarSpecException(
        GrammarDiagnosticCode.facetedSpecNotLowerable,
        'This PlotSpec is faceted. A single-panel lowering (PlotSpec.lower / '
        'BravenChart.build) renders exactly one panel, but a faceted spec is N '
        'panels. Render it with BravenChart.buildFaceted() or BravenFacetPlot.',
      );

  /// `buildFaceted()` was called on a non-faceted spec.
  factory GrammarSpecException.notFaceted() => const GrammarSpecException(
    GrammarDiagnosticCode.notFaceted,
    'buildFaceted() needs a faceted spec, but this chain called no '
    '.facet(...). Add .facet(by: ...), or render it with .build().',
  );

  /// Faceting partitioned zero rows into zero panels.
  factory GrammarSpecException.emptyFacetValues() => const GrammarSpecException(
    GrammarDiagnosticCode.emptyFacetValues,
    'Faceting found no rows to partition, so there is no panel to draw. Pass '
    'the rows the facet accessor reads to PlotSpec.data.',
  );

  /// Faceting produced more panels than the cap allows.
  factory GrammarSpecException.facetPanelCapExceeded(int count, int cap) =>
      GrammarSpecException(
        GrammarDiagnosticCode.facetPanelCapExceeded,
        'Faceting produced $count panels, over the cap of $cap. A grid this '
        'large is a chart-authoring error, not a render — facet by a coarser '
        'field or pre-aggregate the rows.',
      );

  /// A facet declared a non-positive `columns` count.
  factory GrammarSpecException.facetColumnsNotPositive(int columns) =>
      GrammarSpecException(
        GrammarDiagnosticCode.facetColumnsNotPositive,
        'Faceting was asked for $columns columns, but a grid needs a positive '
        'column count. Pass columns: 1 or more, or leave it null to auto-size '
        'the grid.',
      );

  /// A multi-y-axis spec was faceted under a shared-Y scale mode.
  factory GrammarSpecException.facetMultiAxisSharedY(
    int axisCount,
    String scales,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.facetMultiAxisSharedY,
    'This spec declares $axisCount Y axes and facets with a shared-Y scale '
    '($scales), which would collapse every axis onto one global Y range and '
    'silently distort them. Multi-axis faceting needs FacetScales.freeY or '
    'FacetScales.free in v1 (per-axis shared ranges are not computed yet).',
  );

  /// A radial geom was combined with a non-radial mark.
  factory GrammarSpecException.mixedCoordinateSystems(
    String radialMarkId,
    Iterable<String> otherMarkIds,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.mixedCoordinateSystems,
    'The radial mark "$radialMarkId" cannot share a plot with the '
    'non-radial mark(s) ${_list(otherMarkIds)}. Radial and Cartesian '
    'geometries use different coordinate systems; author them as separate '
    'charts.',
  );

  /// A spec declared more than one radial geom.
  factory GrammarSpecException.multipleRadialGeoms(
    Iterable<String> radialMarkIds,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.multipleRadialGeoms,
    'A plot may contain at most one radial geom, but ${_list(radialMarkIds)} '
    'are all radial. Split them into separate charts.',
  );

  /// A Cartesian axis/grid option was set on a radial spec.
  factory GrammarSpecException.axisOptionOnRadialSpec(String option) =>
      GrammarSpecException(
        GrammarDiagnosticCode.axisOptionOnRadialSpec,
        'A radial spec set "$option", but radial charts have no Cartesian '
        'axes or grid. Remove $option; use title, subtitle, legend and theme '
        'instead.',
      );

  /// A radial geom produced no category with a visible label.
  factory GrammarSpecException.emptyRadialCategories(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.emptyRadialCategories,
        'The radial mark "$markId" produced no category with a visible label. '
        'Its category accessor must return a non-empty value for at least one '
        'row.',
      );

  /// A radial spec also requested faceting.
  factory GrammarSpecException.facetedRadialUnsupported(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.facetedRadialUnsupported,
        'The radial mark "$markId" is on a faceted spec. Faceting a radial '
        'geom is not supported; author the radial chart without .facet(...).',
      );

  /// The machine-readable diagnostic.
  final GrammarDiagnosticCode code;

  /// The human-readable explanation, including the remedy.
  final String message;

  static String _list(Iterable<String> values) =>
      values.isEmpty ? '(none)' : values.map((v) => '"$v"').join(', ');

  @override
  String toString() => 'GrammarSpecException(${code.name}): $message';
}
