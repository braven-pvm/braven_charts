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
  /// Raised by the chained `BravenChart` facade, never by [lower] — a
  /// [PlotSpec] cannot express a mark with a missing accessor.
  missingEncoding,
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

  /// The machine-readable diagnostic.
  final GrammarDiagnosticCode code;

  /// The human-readable explanation, including the remedy.
  final String message;

  static String _list(Iterable<String> values) =>
      values.isEmpty ? '(none)' : values.map((v) => '"$v"').join(', ');

  @override
  String toString() => 'GrammarSpecException(${code.name}): $message';
}
