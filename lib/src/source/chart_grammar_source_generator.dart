// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Grammar-chain source generation.
///
/// The Workbench Source pane can show one chart in two forms. The CONFIG form
/// (`ChartDartSourceGenerator`) writes the `BravenChartPlus` a reader would
/// hand-assemble. This library writes the other one: the GRAMMAR CHAIN,
/// `BravenChart.of(rows).x(...).geomLine(...).build()`.
///
/// ## The crux: row synthesis
///
/// A chart document stores MATERIALISED POINTS PER SERIES. The grammar takes
/// the opposite shape — ONE row list plus one total accessor per channel — so
/// the two cannot be bridged by renaming fields. What is emitted instead is a
/// synthesised ROW CLASS: one field for the shared x, one per measure each
/// series reads, named after the series and de-duplicated into valid Dart
/// identifiers.
///
/// The synthesised class is NOT the author's own row type and never can be:
/// the document keeps the numbers a chart was built from, not the objects they
/// came out of. That is the honest limit of the form, and the showcase's
/// hand-written Authoring-code card exists to show the contrast.
///
/// ## Fidelity, and why there is no "best effort" mode
///
/// A chain that renders a DIFFERENT chart is worse than no chain, so this
/// generator never degrades silently. Every shape it cannot express exactly
/// produces a NAMED diagnostic and NO code, in the same comment-header style
/// the config emitter uses for runtime-only bindings. The matrix:
///
/// | case | outcome |
/// |------|---------|
/// | a non-Cartesian family (pie, donut, concentric, polar, range area) | blocked — V1 marks are Cartesian only |
/// | series whose x domains differ | blocked — one row list plus TOTAL accessors cannot express them |
/// | a partially populated scatter channel | blocked — a `Channel` accessor is `num Function(T)`, so it cannot return "no value" |
/// | mixed bar orientations | blocked — `.transposed()` is a whole-chart operation |
/// | a chart-level trend, threshold, range or point annotation | emitted as .trend/.threshold/.band/.pointAt |
/// | any other annotation (text, pin, chord, error-bar, legend, a 2-D/half-open range, or ANY series-level annotation) | blocked and LISTED, never dropped |
/// | a chart-level option `BravenPlot` does not forward (title, legend, grid, size, …) | blocked and named |
/// | anything else the reconstructed chain would not reproduce | blocked by the round-trip proof below |
/// | a runtime interaction binding | emitted with a warning, exactly as the config form does |
/// | data above `maxInlinePoints` | emitted with a placeholder row list and a warning, exactly as the config form does |
///
/// ## The round-trip proof
///
/// Before emitting anything, the generator BUILDS THE SPEC IT IS ABOUT TO
/// WRITE — over an internal row type carrying the same synthesised values —
/// lowers it with the real `PlotSpecLowering`, and compares the resulting
/// `ChartSeries`, `ChartAnnotation`s, Y-axis configs AND the X axis, theme and
/// interaction to the ones the document hydrated to. Anything that does not
/// compare equal is refused. So "the generator emitted a chain" already means
/// "this chain reproduces this chart", without the emitter having to enumerate
/// every option a V1 mark happens not to carry.
library;

import 'dart:ui' show Color;

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_document_hydrator.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/chart_theme_document_codec.dart';
import '../grammar/channel.dart';
import '../grammar/grammar_diagnostics.dart';
import '../grammar/mark.dart';
import '../grammar/plot_lowering.dart';
import '../grammar/plot_spec.dart';
import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/data_point_label_config.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/scatter_marker_style.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'chart_config_dart_emitter.dart';
import 'chart_source_models.dart';
import 'dart_source_writer.dart';

/// Controls grammar-chain generation for one chart document snapshot.
///
/// This mirrors [ChartDartSourceOptions] rather than extending it: the chain
/// has no view-state verb (no controller is created and no viewport is
/// restored), and it has two names the config form does not — the synthesised
/// row class and the row list.
///
/// Like [ChartDartSourceOptions] it deliberately carries NO `copyWith`.
/// Options objects for a generator are constructed once at a call site; giving
/// them a `copyWith` would pull them into the `@chartSurface` fluent model and
/// mint `withVariableName(...)` verbs over a code generator's settings.
class ChartGrammarSourceOptions {
  /// Creates grammar-chain generation options.
  const ChartGrammarSourceOptions({
    this.includeImports = true,
    this.includeDefaultValues = false,
    this.maxInlinePoints = 250,
    this.variableName = 'chart',
    this.rowClassName = 'GrammarRow',
    this.rowsVariableName = 'rows',
    this.formatters = const ChartFormatterRegistry(),
  }) : assert(maxInlinePoints >= 0, 'maxInlinePoints must be non-negative');

  /// Whether package and Material imports precede the generated declaration.
  final bool includeImports;

  /// Whether values equal to public constructor defaults are included.
  final bool includeDefaultValues;

  /// Maximum number of chart points written inline across all series.
  final int maxInlinePoints;

  /// Top-level variable assigned to the generated chart.
  final String variableName;

  /// Name of the synthesised row class the chain's accessors read.
  final String rowClassName;

  /// Name of the synthesised row list handed to `BravenChart.of`.
  final String rowsVariableName;

  /// Runtime formatter implementations used while hydrating the captured
  /// portable document for source generation.
  final ChartFormatterRegistry formatters;
}

/// Stable warning codes emitted by grammar-chain generation.
///
/// [ChartSourceWarningCodes] stays the vocabulary for limitations both forms
/// share (omitted data, runtime values, unsupported portable values); this
/// adds the one that is specific to the chain.
abstract final class ChartGrammarSourceWarningCodes {
  /// The chart cannot be expressed as a grammar chain at all.
  static const unsupportedShape = 'source_grammar_unsupported_shape';
}

/// Generates the `BravenChart.of(rows)…` chain for a captured chart.
abstract final class ChartGrammarSourceGenerator {
  /// Emits the grammar chain for [snapshot], or a diagnostic-only source when
  /// the chart cannot be expressed as one.
  static ChartArtifactResult<ChartGeneratedSource> generate(
    ChartDocumentSnapshot snapshot, {
    ChartGrammarSourceOptions options = const ChartGrammarSourceOptions(),
  }) {
    for (final (label, value) in <(String, String)>[
      ('variableName', options.variableName),
      ('rowClassName', options.rowClassName),
      ('rowsVariableName', options.rowsVariableName),
    ]) {
      if (!DartSourceWriter.isIdentifier(value)) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidArtifact,
            message:
                'Grammar source $label "$value" is not a valid Dart identifier.',
            path: r'$.grammarSourceOptions.' + label,
          ),
        );
      }
    }

    final hydrated = ChartDocumentHydrator.hydrateDocument(
      snapshot.document,
      viewState: snapshot.viewState,
      options: const ChartHydrationOptions(restoreViewState: false),
      runtimeBindings: ChartRuntimeBindings(formatters: options.formatters),
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      return ChartArtifactFailure(
        error: hydrated.error,
        warnings: hydrated.warnings,
      );
    }
    final success =
        hydrated as ChartArtifactSuccess<HydratedChartConfiguration>;
    final generated = _GrammarChainEmitter(
      snapshot: snapshot,
      configuration: success.value,
      options: options,
    ).generate();
    return ChartArtifactSuccess(value: generated, warnings: success.warnings);
  }
}

// ===========================================================================
// The internal row type the round-trip proof lowers over
// ===========================================================================

/// One synthesised row, addressed by SLOT rather than by name.
///
/// The emitted Dart declares a class with real field names; this is the same
/// data reachable positionally, so the spec the proof lowers is built from the
/// identical values without the generator having to compile its own output.
class _SourceRow {
  const _SourceRow(this.numbers, this.strings, this.stamps);

  final List<double> numbers;
  final List<String> strings;
  final List<DateTime?> stamps;
}

enum _FieldKind { number, string, timestamp }

/// One synthesised field: its emitted name, its Dart type and its slot.
class _Field {
  _Field(this.name, this.kind, this.slot);

  final String name;
  final _FieldKind kind;
  final int slot;

  String get typeName => switch (kind) {
    _FieldKind.number => 'double',
    _FieldKind.string => 'String',
    _FieldKind.timestamp => 'DateTime',
  };

  /// The closure the chain passes for this field.
  String accessor() => '(row) => row.$name';
}

/// One geometry the chain will emit: the mark used by the proof, plus the
/// accessor expressions the emitter writes for it.
class _GeometryPlan {
  _GeometryPlan({
    required this.mark,
    required this.series,
    required this.accessors,
  });

  final Mark<_SourceRow> mark;
  final ChartSeries series;
  final Map<String, _Field> accessors;
}

// ===========================================================================
// Emitter
// ===========================================================================

class _GrammarChainEmitter {
  _GrammarChainEmitter({
    required this.snapshot,
    required this.configuration,
    required this.options,
  });

  final ChartDocumentSnapshot snapshot;
  final HydratedChartConfiguration configuration;
  final ChartGrammarSourceOptions options;

  /// `BravenChartPlus.backgroundColor`'s constructor default — what a chart
  /// built by `BravenPlot`, which never passes the parameter, is left at.
  static const Color _chartPlusDefaultBackground = Color(0xFFFFFFFF);

  final List<ChartSourceWarning> _warnings = [];
  final List<_Field> _fields = [];
  final Set<String> _usedNames = <String>{};
  var _numberSlots = 0;
  var _stringSlots = 0;
  var _stampSlots = 0;

  late final bool _omitData =
      snapshot.document.pointCount > options.maxInlinePoints;

  /// The config emitter, used ONLY as a sub-expression writer so the two forms
  /// cannot disagree about how a `YAxisConfig` or a `ChartTheme` is written.
  late final ChartConfigDartEmitter _config = ChartConfigDartEmitter(
    snapshot: snapshot,
    configuration: configuration,
    options: ChartDartSourceOptions(
      includeDefaultValues: options.includeDefaultValues,
      maxInlinePoints: options.maxInlinePoints,
      variableName: options.variableName,
      formatters: options.formatters,
    ),
  );

  ChartGeneratedSource generate() {
    final blocked = <String>[];
    final body = _tryEmitChain(blocked);

    final writer = DartSourceWriter();
    if (body != null && options.includeImports) {
      writer.writeLine("import 'package:braven_charts/braven_charts.dart';");
      writer.writeLine("import 'package:flutter/material.dart';");
      writer.writeLine();
    }
    if (body == null) {
      writer.writeLine('// The grammar chain was not emitted for this chart.');
      for (final reason in blocked) {
        writer.writeLine('//');
        for (final line in _wrapComment(reason)) {
          writer.writeLine('// $line');
        }
      }
      writer.writeLine('//');
      writer.writeLine(
        '// Switch this pane to Config to read the chart as ordinary',
      );
      writer.writeLine('// BravenChartPlus configuration.');
    } else {
      if (_warnings.isNotEmpty) {
        writer.writeLine(
          '// Generated from the current effective chart configuration.',
        );
        for (final warning in _warnings) {
          for (final line in _wrapComment(warning.message)) {
            writer.writeLine('// $line');
          }
        }
        writer.writeLine();
      }
      writer.write(body);
    }

    return ChartGeneratedSource(
      source: writer.toString(),
      revision: snapshot.revision,
      completeness: _warnings.isEmpty
          ? ChartGeneratedSourceCompleteness.complete
          : ChartGeneratedSourceCompleteness.portableWithPlaceholders,
      warnings: _warnings,
      seriesCount: configuration.series.length,
      pointCount: snapshot.document.pointCount,
      omittedPointCount: _omitData ? snapshot.document.pointCount : 0,
    );
  }

  /// Returns the chain body, or null after recording blocking diagnostics.
  String? _tryEmitChain(List<String> blocked) {
    void block(String message, {String? path}) {
      blocked.add(message);
      _warn(
        code: ChartGrammarSourceWarningCodes.unsupportedShape,
        message: message,
        path: path,
      );
    }

    final series = configuration.series;
    if (series.isEmpty) {
      block(
        'Grammar chain not emitted: the chart has no series, and a '
        'BravenChart chain must declare at least one geometry.',
        path: r'$.series',
      );
      return null;
    }

    // ---- 1. family gate -------------------------------------------------
    final unsupportedFamilies = <String>[];
    for (final item in series) {
      if (!_isCartesianFamily(item)) {
        unsupportedFamilies.add('${item.id} (${item.runtimeType})');
      }
    }
    if (unsupportedFamilies.isNotEmpty) {
      block(
        'Grammar chain not emitted: the grammar layer is Cartesian-only in V1 '
        '(line, area, bar, scatter and candlestick marks). These series have '
        'no V1 mark: ${unsupportedFamilies.join(', ')}.',
        path: r'$.series[*].type',
      );
      return null;
    }

    // ---- 2. chart-level options BravenPlot does not forward --------------
    final unsupportedChartOptions = _unsupportedChartOptions();
    if (unsupportedChartOptions.isNotEmpty) {
      block(
        'Grammar chain not emitted: BravenPlot forwards series, annotations, '
        'the X axis, interaction, the theme, the grid, the title, the subtitle '
        'and legend visibility, so these remaining chart-level options would be '
        'lost: ${unsupportedChartOptions.join(', ')}.',
        path: r'$.layout',
      );
      return null;
    }

    // ---- 3. transposition ------------------------------------------------
    final horizontal = <String>[];
    final vertical = <String>[];
    for (final item in series) {
      if (item is BarChartSeries) {
        (item.orientation == BarOrientation.horizontal ? horizontal : vertical)
            .add(item.id);
      } else {
        vertical.add(item.id);
      }
    }
    if (horizontal.isNotEmpty && vertical.isNotEmpty) {
      block(
        'Grammar chain not emitted: .transposed() is a whole-chart operation, '
        'so a transposed chain may contain horizontal bar marks only. '
        'Horizontal: ${horizontal.join(', ')}. Not horizontal: '
        '${vertical.join(', ')}.',
        path: r'$.series[*].orientation',
      );
      return null;
    }
    final transposed = horizontal.isNotEmpty;

    // ---- 4. x alignment ---------------------------------------------------
    final xValues = _xValuesOf(series.first);
    final misaligned = <String>[];
    for (final item in series.skip(1)) {
      if (!_sameXDomain(xValues, _xValuesOf(item))) misaligned.add(item.id);
    }
    if (misaligned.isNotEmpty) {
      block(
        'Grammar chain not emitted: one row list cannot express series whose '
        'x domains differ. BravenChart.of(rows) hands every mark the same rows '
        'and every accessor is total (num Function(T)), so each series must '
        'have exactly one value at every x of the shared domain. "'
        '${series.first.id}" sets the domain; these series do not match it: '
        '${misaligned.join(', ')}.',
        path: r'$.series[*].data',
      );
      return null;
    }

    // ---- 5. annotations ---------------------------------------------------
    // Chart-level trend, threshold, band and point annotations each have a
    // chain verb (a reference mark). Every OTHER annotation type — and ALL
    // series-level annotations, which the grammar can only ever produce at
    // chart level — has none, and is listed rather than dropped. A range that
    // is not a clean 1-D band (a 2-D box, or a half-open bound) has no
    // BandMark either, so `_annotationMark` returns null for it and it lands
    // here too.
    final inexpressible = <String>[];
    for (final annotation in configuration.annotations) {
      if (_annotationMark(annotation) == null) {
        inexpressible.add('${annotation.id} (${annotation.runtimeType})');
      }
    }
    for (final item in series) {
      for (final annotation in item.annotations) {
        inexpressible.add(
          '${annotation.id} (${annotation.runtimeType}, on series ${item.id})',
        );
      }
    }
    if (inexpressible.isNotEmpty) {
      block(
        'Grammar chain not emitted: the chain expresses only trend, threshold, '
        'band and point reference annotations, through .trend(of:), '
        '.threshold(), .band() and .pointAt(). These annotations have no chain '
        'verb and are not dropped silently: ${inexpressible.join(', ')}.',
        path: r'$.annotations',
      );
      return null;
    }

    // ---- 6. scatter channel totality --------------------------------------
    for (final item in series) {
      if (item is! ScatterChartSeries) continue;
      final partial = _partialChannels(item);
      if (partial.isEmpty) continue;
      block(
        'Grammar chain not emitted: series "${item.id}" has '
        '${partial.join(', ')}. A Channel accessor is total '
        '(num Function(T)), so it cannot express "no value at this row".',
        path: r'$.series[*].data',
      );
      return null;
    }

    // ---- 6b. candlestick timestamp totality -------------------------------
    // A candlestick's optional timestamp is expressed as a total
    // DateTime Function(T) accessor, exactly like a scatter channel, so a
    // timestamp present on SOME candles but not all cannot be reproduced. This
    // MUST gate before geometry planning: `_planGeometry` would otherwise
    // synthesise a timestamp field (on `.any`) and the round-trip proof's
    // lowering would dereference a null slot for the timestamp-less rows,
    // crashing the generator with an opaque null-check TypeError instead of
    // reporting a clean diagnostic.
    for (final item in series) {
      if (item is! CandlestickChartSeries) continue;
      final total = item.candles.length;
      final stamped = item.candles
          .where((candle) => candle.timestamp != null)
          .length;
      if (stamped == 0 || stamped == total) continue;
      block(
        'Grammar chain not emitted: series "${item.id}" carries a timestamp on '
        '$stamped of $total candles. A Channel/accessor is total '
        '(DateTime Function(T)), so a partial timestamp cannot be expressed — '
        'give every candle a timestamp, or none.',
        path: r'$.series[*].data',
      );
      return null;
    }

    // ---- 7. build the synthesised fields and the candidate marks ----------
    _usedNames.add(options.rowsVariableName);
    final xField = _addField('x', _FieldKind.number);
    final geometries = <_GeometryPlan>[];
    for (final item in series) {
      geometries.add(_planGeometry(item, xField));
    }
    // Every chart-level annotation passed the gate above, so each maps to a
    // reference mark. Their order is preserved, which is what keeps the
    // round-trip proof's index-by-index annotation comparison honest.
    final marks = <Mark<_SourceRow>>[
      for (final plan in geometries) plan.mark,
      for (final annotation in configuration.annotations)
        _annotationMark(annotation)!,
    ];

    // ---- 8. the round-trip proof -----------------------------------------
    final rows = _synthesiseRows(series, xValues.length);
    _fillRows(rows, geometries);
    final spec = PlotSpec<_SourceRow>(
      data: rows,
      marks: marks,
      transposed: transposed,
      theme: configuration.theme,
      interaction: configuration.interaction,
      xAxis: configuration.xAxis,
      yAxes: configuration.axes,
      grid: configuration.grid,
      title: configuration.title,
      subtitle: configuration.subtitle,
      showLegend: configuration.showLegend,
    );
    final LoweredPlot lowered;
    try {
      lowered = spec.lower();
    } on GrammarSpecException catch (error) {
      block(
        'Grammar chain not emitted: the reconstructed specification was '
        'rejected by the grammar layer — ${error.message}',
        path: r'$.series',
      );
      return null;
    }
    final mismatch = _firstMismatch(lowered);
    if (mismatch != null) {
      block(
        'Grammar chain not emitted: the reconstructed chain does not reproduce '
        '${mismatch.subject} exactly, so writing it would hand back a '
        'different chart. ${mismatch.detail}',
        path: r'$.series',
      );
      return null;
    }

    // ---- 9. non-blocking limitations, then emit ---------------------------
    _captureKnownLimitations();
    return _emitBody(
      geometries: geometries,
      transposed: transposed,
      xField: xField,
      rows: rows,
    );
  }

  // =========================================================================
  // Gates
  // =========================================================================

  bool _isCartesianFamily(ChartSeries series) => switch (series) {
    CandlestickChartSeries() => true,
    LineChartSeries() => true,
    ScatterChartSeries() => true,
    AreaChartSeries() => true,
    BarChartSeries() => true,
    _ => false,
  };

  /// Chart-level options `BravenPlot` leaves at their `BravenChartPlus`
  /// defaults, and which a chain therefore cannot carry.
  ///
  /// Grid, title, subtitle and legend visibility are NOT here: `PlotSpec`
  /// carries them and the chain emits `.grid(...)` / `.title(...)` /
  /// `.legend(...)` below. The one carried-but-inexpressible corner is a
  /// subtitle with no title — the `.title(String, {String? subtitle})` verb can
  /// only attach a subtitle to a title — so that alone stays gated rather than
  /// being dropped silently.
  List<String> _unsupportedChartOptions() {
    final lost = <String>[];
    if (configuration.subtitle != null && configuration.title == null) {
      lost.add('a subtitle with no title');
    }
    if (configuration.showToolbar) lost.add('showToolbar: true');
    if (!configuration.interactiveAnnotations) {
      lost.add('interactiveAnnotations: false');
    }
    if (configuration.maxAxesPerSide != 3) {
      lost.add('maxAxesPerSide: ${configuration.maxAxesPerSide}');
    }
    if (configuration.axisSwapMode.name != 'sticky') {
      lost.add('axisSwapMode: ${configuration.axisSwapMode.name}');
    }
    if (configuration.normalizationMode.name != 'none') {
      lost.add('normalizationMode: ${configuration.normalizationMode.name}');
    }
    if (configuration.width != null) lost.add('width');
    if (configuration.height != null) lost.add('height');
    // `BravenChartPlus.backgroundColor` defaults to white and `legendStyle`
    // defaults to the theme's — which the chain DOES carry — so both are only
    // lost when they were overridden away from those defaults.
    if (configuration.backgroundColor != _chartPlusDefaultBackground) {
      lost.add('backgroundColor');
    }
    if (configuration.legendStyle != configuration.theme.legendStyle) {
      lost.add('legendStyle');
    }
    if (configuration.concentricDonutConfig != null) {
      lost.add('concentricDonutConfig');
    }
    if (configuration.polarChartConfig != null) lost.add('polarChartConfig');
    return lost;
  }

  List<double> _xValuesOf(ChartSeries series) => <double>[
    for (final point in series.points) point.x,
  ];

  bool _sameXDomain(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      // NaN never compares equal, which is exactly right: a gap expressed as a
      // non-finite x cannot be a shared row key.
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  List<String> _partialChannels(ScatterChartSeries series) {
    final total = series.points.length;
    final partial = <String>[];
    void check(String name, int populated) {
      if (populated != 0 && populated != total) {
        partial.add('$name on $populated of $total points');
      }
    }

    check(
      'magnitude',
      series.points.where((point) => point.magnitude != null).length,
    );
    check(
      'colorValue',
      series.points.where((point) => point.colorValue != null).length,
    );
    check(
      'opacityValue',
      series.points.where((point) => point.opacityValue != null).length,
    );
    check(
      'categoryValue',
      series.points.where((point) => point.categoryValue != null).length,
    );
    return partial;
  }

  /// The generic tail used when the specific option cannot be pinned down
  /// cheaply (a list-length change, an annotation or an axis difference).
  static const String _genericLossDetail =
      'This is normally a series, annotation or axis option that no V1 mark '
      'carries.';

  /// The first part of the lowered plot that does not match the captured
  /// chart, described for a diagnostic, or null when everything matches.
  ///
  /// [subject] names what differs (a series, annotation, Y axis, the X axis,
  /// the theme or the interaction configuration); [detail] says WHY it differs
  /// — naming the specific option a V1 mark cannot carry whenever that can be
  /// identified cheaply from the round-trip comparison the emitter already
  /// runs, so the reader learns the boundary instead of only reading "does not
  /// reproduce exactly".
  ({String subject, String detail})? _firstMismatch(LoweredPlot lowered) {
    if (lowered.series.length != configuration.series.length) {
      return (subject: 'the series list', detail: _genericLossDetail);
    }
    for (var index = 0; index < lowered.series.length; index++) {
      final expected = configuration.series[index];
      if (lowered.series[index] != expected) {
        return (
          subject: 'series "${expected.id}"',
          detail: _seriesLossDetail(expected, lowered.series[index]),
        );
      }
    }
    if (lowered.annotations.length != configuration.annotations.length) {
      return (subject: 'the annotation list', detail: _genericLossDetail);
    }
    for (var index = 0; index < lowered.annotations.length; index++) {
      final expected = configuration.annotations[index];
      final actual = lowered.annotations[index];
      if (!_sameAnnotation(expected, actual)) {
        return (
          subject: 'annotation "${expected.id}"',
          detail: _genericLossDetail,
        );
      }
    }
    if (lowered.yAxes.length != configuration.axes.length) {
      return (subject: 'the Y-axis list', detail: _genericLossDetail);
    }
    for (var index = 0; index < lowered.yAxes.length; index++) {
      if (lowered.yAxes[index] != configuration.axes[index]) {
        return (
          subject: 'the Y axis "${configuration.axes[index].id}"',
          detail: _genericLossDetail,
        );
      }
    }
    // The X axis, theme and interaction are carried verbatim by lowering and
    // re-emitted by the shared config emitter. Comparing them here closes the
    // loop so the "emitted == faithful" guarantee genuinely covers every field
    // a LoweredPlot carries — not only series, annotations and Y-axes. Each is
    // guarded by a complete operator==, so a captured value the chain cannot
    // reproduce is refused rather than silently diverging.
    if (lowered.xAxis != configuration.xAxis) {
      return (subject: 'the X axis', detail: _genericLossDetail);
    }
    if (lowered.theme != configuration.theme) {
      return (subject: 'the theme', detail: _genericLossDetail);
    }
    if (lowered.interaction != configuration.interaction) {
      return (
        subject: 'the interaction configuration',
        detail: _genericLossDetail,
      );
    }
    // Grid, title, subtitle and legend visibility are carried verbatim by
    // lowering too, so — like the X axis, theme and interaction above — they are
    // compared here to keep the "emitted == faithful" guarantee covering every
    // field a LoweredPlot carries, rather than dropping any of them.
    if (lowered.grid != configuration.grid) {
      return (subject: 'the grid', detail: _genericLossDetail);
    }
    if (lowered.title != configuration.title) {
      return (subject: 'the title', detail: _genericLossDetail);
    }
    if (lowered.subtitle != configuration.subtitle) {
      return (subject: 'the subtitle', detail: _genericLossDetail);
    }
    if (lowered.showLegend != configuration.showLegend) {
      return (subject: 'the legend visibility', detail: _genericLossDetail);
    }
    return null;
  }

  /// Explains why a captured [expected] series is not reproduced by the
  /// [lowered] one the grammar rebuilds.
  ///
  /// The lowered series is built by carrying exactly the fields the mark
  /// supports and defaulting the rest, so the fields that differ are precisely
  /// the options no V1 mark carries. Naming the first such field turns "does
  /// not reproduce exactly" into an actionable boundary. When the only
  /// difference is the axis binding — the captured chart used the single-axis
  /// path and left `yAxisId` unset, while the grammar always binds every
  /// series to an explicit axis — that is called out specifically, because it
  /// is the usual reason a config-authored single-axis chart cannot round-trip.
  String _seriesLossDetail(ChartSeries expected, ChartSeries lowered) {
    final field = _firstUncarriedField(expected, lowered);
    if (field != null) {
      return 'It carries $field, which no V1 ${_familyWord(expected)} mark '
          'carries.';
    }
    if (expected.yAxisId != lowered.yAxisId ||
        (expected.yAxisConfig == null) != (lowered.yAxisConfig == null)) {
      return 'The captured chart leaves this series\' yAxisId unset (the '
          'single-axis path), while the grammar binds every series to an '
          'explicit axis, so the reconstructed chain would render a different '
          'chart document. Author the chart through the grammar, or with '
          'explicit .yAxis(...) declarations, to express it as a chain.';
    }
    return _genericLossDetail;
  }

  /// The English family word for [series], for the diagnostic sentence.
  static String _familyWord(ChartSeries series) => switch (series) {
    LineChartSeries() => 'line',
    AreaChartSeries() => 'area',
    BarChartSeries() => 'bar',
    ScatterChartSeries() => 'scatter',
    CandlestickChartSeries() => 'candlestick',
    _ => 'V1',
  };

  /// The first option set on [expected] that the [lowered] series does not
  /// carry, phrased for a diagnostic, or null when the two differ only in
  /// their axis binding (handled separately) or in a field not enumerated
  /// here. The order walks the shared fields first, then the family-specific
  /// ones, so the most common culprit is named first.
  String? _firstUncarriedField(ChartSeries expected, ChartSeries lowered) {
    if (expected.unit != lowered.unit) {
      return "a unit ('${expected.unit}')";
    }
    switch (expected) {
      case LineChartSeries():
        final actual = lowered as LineChartSeries;
        // showDataPointMarkers and dataPointLabels are now carried by LineMark,
        // so they are no longer in the uncarried set.
        if (expected.dataPointMarkerRadius != actual.dataPointMarkerRadius) {
          return 'a data-point marker radius';
        }
        if (expected.dataPointMarkerStyle != actual.dataPointMarkerStyle) {
          return 'a data-point marker style';
        }
        if (expected.tension != actual.tension) return 'a curve tension';
        if (expected.lineGlow != actual.lineGlow) return 'a line glow';
        if (expected.inlineLabel != actual.inlineLabel) {
          return 'an inline series label';
        }
        if (expected.pathAnimation != actual.pathAnimation) {
          return 'a path animation';
        }
      case AreaChartSeries():
        final actual = lowered as AreaChartSeries;
        // showDataPointMarkers and dataPointLabels are now carried by AreaMark,
        // so they are no longer in the uncarried set.
        if (expected.dataPointMarkerRadius != actual.dataPointMarkerRadius) {
          return 'a data-point marker radius';
        }
        if (expected.fillGradient != actual.fillGradient) {
          return 'a fill gradient';
        }
        if (expected.aboveBaselineFillColor != actual.aboveBaselineFillColor ||
            expected.belowBaselineFillColor != actual.belowBaselineFillColor) {
          return 'a split baseline fill';
        }
        if (expected.lineGlow != actual.lineGlow) return 'a line glow';
        if (expected.inlineLabel != actual.inlineLabel) {
          return 'an inline series label';
        }
        if (expected.pathAnimation != actual.pathAnimation) {
          return 'a path animation';
        }
      case BarChartSeries():
        final actual = lowered as BarChartSeries;
        // labelStyle is now carried by BarMark, so it is no longer in the
        // uncarried set.
        if (expected.barStyle != actual.barStyle) return 'a bar style';
        if (expected.trackStyle != actual.trackStyle) return 'a track style';
        if (expected.divergingStyle != actual.divergingStyle) {
          return 'a diverging-bar style';
        }
      case ScatterChartSeries():
        final actual = lowered as ScatterChartSeries;
        if (expected.dataPointLabels != actual.dataPointLabels) {
          return 'a data-point label configuration';
        }
        if (expected.renderMode != actual.renderMode) {
          return 'a non-default render mode';
        }
        if (expected.jitter != actual.jitter) return 'a jitter configuration';
        if (expected.interactionStyle != actual.interactionStyle) {
          return 'an interaction style';
        }
      case CandlestickChartSeries():
        // Open/high/low/close and the timestamp are carried in full; any
        // remaining styling difference falls through to the generic tail.
        break;
    }
    return null;
  }

  /// Structural equality for two annotations of the SAME expressible type.
  ///
  /// The annotation hierarchy is identity-compared, so each expressible type
  /// gets a hand-written full-field comparison below. A pair of different
  /// runtime types (or an unmapped type) compares unequal, which refuses the
  /// chain — the safe direction.
  static bool _sameAnnotation(ChartAnnotation a, ChartAnnotation b) {
    if (a is TrendAnnotation && b is TrendAnnotation) return _sameTrend(a, b);
    if (a is ThresholdAnnotation && b is ThresholdAnnotation) {
      return _sameThreshold(a, b);
    }
    if (a is RangeAnnotation && b is RangeAnnotation) return _sameRange(a, b);
    if (a is PointAnnotation && b is PointAnnotation) return _samePoint(a, b);
    return false;
  }

  /// Full-field equality for a [ThresholdAnnotation].
  ///
  /// Compares EVERY field, including the ones a `ThresholdMark` cannot carry
  /// (`seriesId`, `labelPosition`, `labelMargin`, `elevation`, `style`,
  /// `zIndex`, the snap knobs, `allowDragging`/`allowEditing`). A captured
  /// threshold that sets one of them is REFUSED rather than emitted as a chain
  /// that silently drops it.
  static bool _sameThreshold(ThresholdAnnotation a, ThresholdAnnotation b) =>
      a.id == b.id &&
      a.label == b.label &&
      a.axis == b.axis &&
      a.value == b.value &&
      a.seriesId == b.seriesId &&
      a.lineColor == b.lineColor &&
      a.lineWidth == b.lineWidth &&
      _sameDashPattern(a.dashPattern, b.dashPattern) &&
      a.labelPosition == b.labelPosition &&
      a.labelMargin == b.labelMargin &&
      a.elevation == b.elevation &&
      a.style == b.style &&
      a.allowDragging == b.allowDragging &&
      a.allowEditing == b.allowEditing &&
      a.zIndex == b.zIndex &&
      a.snapToValue == b.snapToValue &&
      a.snapIncrement == b.snapIncrement;

  /// Full-field equality for a [RangeAnnotation]. Fields a `BandMark` cannot
  /// carry (`borderColor`, `seriesId`, `labelPosition`, `labelMargin`,
  /// `snapTolerance`, the 2-D box / half-open bounds it never produces, and
  /// the base flags) are compared, so a captured range that sets one is
  /// refused rather than silently narrowed to a plain band.
  static bool _sameRange(RangeAnnotation a, RangeAnnotation b) =>
      a.id == b.id &&
      a.label == b.label &&
      a.startX == b.startX &&
      a.endX == b.endX &&
      a.startY == b.startY &&
      a.endY == b.endY &&
      a.seriesId == b.seriesId &&
      a.fillColor == b.fillColor &&
      a.borderColor == b.borderColor &&
      a.labelPosition == b.labelPosition &&
      a.labelMargin == b.labelMargin &&
      a.snapTolerance == b.snapTolerance &&
      a.style == b.style &&
      a.allowDragging == b.allowDragging &&
      a.allowEditing == b.allowEditing &&
      a.zIndex == b.zIndex &&
      a.snapToValue == b.snapToValue &&
      a.snapIncrement == b.snapIncrement;

  /// Full-field equality for a [PointAnnotation]. Fields a `PointMark` cannot
  /// carry (`offset`, `labelMargin`, `style`, `zIndex`, the base flags) are
  /// compared, so a captured point that sets one is refused rather than
  /// emitted as a chain that drops it.
  static bool _samePoint(PointAnnotation a, PointAnnotation b) =>
      a.id == b.id &&
      a.label == b.label &&
      a.seriesId == b.seriesId &&
      a.dataPointIndex == b.dataPointIndex &&
      a.offset == b.offset &&
      a.markerShape == b.markerShape &&
      a.markerSize == b.markerSize &&
      a.markerColor == b.markerColor &&
      a.labelMargin == b.labelMargin &&
      a.style == b.style &&
      a.allowDragging == b.allowDragging &&
      a.allowEditing == b.allowEditing &&
      a.zIndex == b.zIndex;

  /// Structural equality for a [TrendAnnotation].
  ///
  /// The annotation hierarchy is identity-compared — `ChartAnnotation` declares
  /// no `operator ==` — so the proof has to spell the comparison out. Every
  /// field is compared, INCLUDING the ones a `TrendMark` cannot carry
  /// (`degree`, the LOESS knobs, the readouts, the prediction band, `style`,
  /// `zIndex`, …). That is deliberate: a captured trend that sets one of them
  /// must be REFUSED rather than emitted as a chain that silently drops it.
  static bool _sameTrend(TrendAnnotation a, TrendAnnotation b) =>
      a.id == b.id &&
      a.label == b.label &&
      a.seriesId == b.seriesId &&
      a.trendType == b.trendType &&
      a.windowSize == b.windowSize &&
      a.degree == b.degree &&
      a.loessSpan == b.loessSpan &&
      a.loessRobustnessIterations == b.loessRobustnessIterations &&
      a.loessSampleCount == b.loessSampleCount &&
      a.showEquation == b.showEquation &&
      a.showRSquared == b.showRSquared &&
      a.showSampleCount == b.showSampleCount &&
      a.showPearsonCorrelation == b.showPearsonCorrelation &&
      a.showSpearmanCorrelation == b.showSpearmanCorrelation &&
      a.showConfidenceBand == b.showConfidenceBand &&
      a.showPredictionBand == b.showPredictionBand &&
      a.confidenceLevel == b.confidenceLevel &&
      a.confidenceBandColor == b.confidenceBandColor &&
      a.predictionBandColor == b.predictionBandColor &&
      a.confidenceBandOpacity == b.confidenceBandOpacity &&
      a.predictionBandOpacity == b.predictionBandOpacity &&
      a.lineColor == b.lineColor &&
      a.lineWidth == b.lineWidth &&
      _sameDashPattern(a.dashPattern, b.dashPattern) &&
      a.elevation == b.elevation &&
      a.style == b.style &&
      a.allowDragging == b.allowDragging &&
      a.allowEditing == b.allowEditing &&
      a.zIndex == b.zIndex &&
      a.snapToValue == b.snapToValue &&
      a.snapIncrement == b.snapIncrement;

  static bool _sameDashPattern(List<double>? a, List<double>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // =========================================================================
  // Field synthesis
  // =========================================================================

  _Field _addField(String preferred, _FieldKind kind) {
    final name = _uniqueName(preferred);
    final slot = switch (kind) {
      _FieldKind.number => _numberSlots++,
      _FieldKind.string => _stringSlots++,
      _FieldKind.timestamp => _stampSlots++,
    };
    final field = _Field(name, kind, slot);
    _fields.add(field);
    return field;
  }

  String _uniqueName(String preferred) {
    final base = _identifier(preferred);
    var candidate = base;
    var suffix = 2;
    while (!_usedNames.add(candidate)) {
      candidate = '$base$suffix';
      suffix += 1;
    }
    return candidate;
  }

  /// Lower-camel-cases [source] into a valid, non-keyword Dart identifier.
  static String _identifier(String source) {
    final words = source
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'field';
    final buffer = StringBuffer();
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      if (index == 0) {
        buffer.write(word[0].toLowerCase());
      } else {
        buffer.write(word[0].toUpperCase());
      }
      buffer.write(word.substring(1));
    }
    var name = buffer.toString();
    if (RegExp(r'^[0-9]').hasMatch(name)) name = 'field$name';
    if (DartSourceWriter.dartKeywords.contains(name)) name = '${name}Value';
    return name;
  }

  String _baseNameFor(ChartSeries series) =>
      (series.name == null || series.name!.trim().isEmpty)
      ? series.id
      : series.name!;

  /// `power` + `Open` → `powerOpen`.
  String _suffixed(String base, String suffix) =>
      '$base${suffix[0].toUpperCase()}${suffix.substring(1)}';

  // =========================================================================
  // Geometry planning
  // =========================================================================

  double Function(_SourceRow) _number(_Field field) =>
      (row) => row.numbers[field.slot];

  Object Function(_SourceRow) _string(_Field field) =>
      (row) => row.strings[field.slot];

  DateTime Function(_SourceRow) _stamp(_Field field) =>
      (row) => row.stamps[field.slot]!;

  _GeometryPlan _planGeometry(ChartSeries series, _Field xField) {
    final base = _identifier(_baseNameFor(series));
    final accessors = <String, _Field>{'x': xField};
    final x = _number(xField);
    final id = series.id;
    final name = series.name;
    final color = series.color;
    final yAxisId = series.yAxisId;

    switch (series) {
      case CandlestickChartSeries():
        final open = _addField(_suffixed(base, 'open'), _FieldKind.number);
        final high = _addField(_suffixed(base, 'high'), _FieldKind.number);
        final low = _addField(_suffixed(base, 'low'), _FieldKind.number);
        final close = _addField(_suffixed(base, 'close'), _FieldKind.number);
        accessors
          ..['open'] = open
          ..['high'] = high
          ..['low'] = low
          ..['close'] = close;
        _Field? stamp;
        if (series.points.any((point) => point.timestamp != null)) {
          stamp = _addField(_suffixed(base, 'timestamp'), _FieldKind.timestamp);
          accessors['timestamp'] = stamp;
        }
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: CandlestickMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            yAxisId: yAxisId,
            x: x,
            open: _number(open),
            high: _number(high),
            low: _number(low),
            close: _number(close),
            timestamp: stamp == null ? null : _stamp(stamp),
          ),
        );

      case LineChartSeries():
        final y = _addField(base, _FieldKind.number);
        accessors['y'] = y;
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: LineMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            yAxisId: yAxisId,
            x: x,
            y: _number(y),
            strokeWidth: series.strokeWidth,
            dashPattern: series.dashPattern,
            interpolation: series.interpolation,
            showDataPointMarkers: series.showDataPointMarkers,
            dataPointLabels: series.dataPointLabels,
          ),
        );

      case ScatterChartSeries():
        final y = _addField(base, _FieldKind.number);
        accessors['y'] = y;
        Channel<_SourceRow>? quantitative(
          String role,
          double? Function(ChartDataPoint) read,
        ) {
          if (series.points.every((point) => read(point) == null)) return null;
          final field = _addField(_suffixed(base, role), _FieldKind.number);
          accessors[role] = field;
          return Channel<_SourceRow>(_number(field));
        }

        final size = quantitative('size', (point) => point.magnitude);
        final colorBy = quantitative('color', (point) => point.colorValue);
        final opacityBy = quantitative(
          'opacity',
          (point) => point.opacityValue,
        );
        CategoryChannel<_SourceRow>? categoryBy;
        if (series.points.any((point) => point.categoryValue != null)) {
          final field = _addField(
            _suffixed(base, 'category'),
            _FieldKind.string,
          );
          accessors['category'] = field;
          categoryBy = CategoryChannel<_SourceRow>(
            _string(field),
            label: series.categoryEncoding?.label,
          );
        }
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: ScatterMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            yAxisId: yAxisId,
            x: x,
            y: _number(y),
            size: size,
            sizeEncoding: series.sizeEncoding,
            colorBy: colorBy,
            colorEncoding: series.colorEncoding,
            opacityBy: opacityBy,
            opacityEncoding: series.opacityEncoding,
            categoryBy: categoryBy,
            categories:
                series.categoryEncoding?.categories ??
                const <ScatterCategoryStyle>[],
            markerRadius: series.markerRadius,
            markerShape: series.markerShape,
            markerStyle: series.markerStyle,
          ),
        );

      case AreaChartSeries():
        final y = _addField(base, _FieldKind.number);
        accessors['y'] = y;
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: AreaMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            yAxisId: yAxisId,
            x: x,
            y: _number(y),
            baseline: series.baselineValue,
            fillOpacity: series.fillOpacity,
            strokeWidth: series.strokeWidth,
            dashPattern: series.dashPattern,
            interpolation: series.interpolation,
            showDataPointMarkers: series.showDataPointMarkers,
            dataPointLabels: series.dataPointLabels,
          ),
        );

      case BarChartSeries():
        final y = _addField(base, _FieldKind.number);
        accessors['y'] = y;
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: BarMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            yAxisId: yAxisId,
            x: x,
            y: _number(y),
            barWidthPercent: series.barWidthPercent,
            barWidthPixels: series.barWidthPixels,
            barGap: series.barGap,
            layoutMode: series.layoutMode,
            groupId: series.groupId,
            baselineValue: series.baselineValue,
            labelStyle: series.labelStyle,
          ),
        );

      case ChartSeries():
        throw StateError('unreachable: the family gate rejected ${series.id}');
    }
  }

  TrendMark<_SourceRow> _planTrend(TrendAnnotation annotation) =>
      TrendMark<_SourceRow>(
        id: annotation.id,
        sourceMarkId: annotation.seriesId,
        name: annotation.label,
        color: annotation.lineColor,
        trendType: annotation.trendType,
        windowSize: annotation.windowSize,
        showConfidenceBand: annotation.showConfidenceBand,
        lineWidth: annotation.lineWidth,
        dashPattern: annotation.dashPattern,
      );

  /// The reference mark a chart-level [annotation] round-trips through, or null
  /// when no V1 chain verb expresses it.
  ///
  /// This is the single source of truth the annotation gate and the mark
  /// planner share: an annotation is expressible iff this returns non-null.
  Mark<_SourceRow>? _annotationMark(ChartAnnotation annotation) =>
      switch (annotation) {
        TrendAnnotation() => _planTrend(annotation),
        ThresholdAnnotation() => _planThreshold(annotation),
        PointAnnotation() => _planPoint(annotation),
        RangeAnnotation() => _planBand(annotation),
        // TextAnnotation, PinAnnotation, ChordAnnotation, ErrorBarAnnotation
        // and LegendAnnotation have no chain verb.
        _ => null,
      };

  ThresholdMark<_SourceRow> _planThreshold(ThresholdAnnotation annotation) =>
      ThresholdMark<_SourceRow>(
        id: annotation.id,
        value: annotation.value,
        axis: annotation.axis,
        label: annotation.label,
        color: annotation.lineColor,
        strokeWidth: annotation.lineWidth,
        dashPattern: annotation.dashPattern,
      );

  PointMark<_SourceRow> _planPoint(PointAnnotation annotation) =>
      PointMark<_SourceRow>(
        id: annotation.id,
        seriesId: annotation.seriesId,
        dataPointIndex: annotation.dataPointIndex,
        label: annotation.label,
        color: annotation.markerColor,
        markerSize: annotation.markerSize,
        markerShape: annotation.markerShape,
      );

  /// A [BandMark] for a clean 1-D range, or null for a 2-D box or a half-open
  /// bound — a `BandMark` cannot express either, so those ranges stay gated.
  BandMark<_SourceRow>? _planBand(RangeAnnotation annotation) {
    final axis = _bandAxis(annotation);
    if (axis == null) return null;
    final isY = axis == AnnotationAxis.y;
    return BandMark<_SourceRow>(
      id: annotation.id,
      start: (isY ? annotation.startY : annotation.startX)!,
      end: (isY ? annotation.endY : annotation.endX)!,
      axis: axis,
      label: annotation.label,
      color: annotation.fillColor,
    );
  }

  /// The single axis a [range] spans, or null when it is not a clean 1-D band:
  /// a half-open bound (one side null), a 2-D box (both pairs set), or neither
  /// pair set — none of which a `BandMark` can carry.
  static AnnotationAxis? _bandAxis(RangeAnnotation range) {
    final xClean = (range.startX == null) == (range.endX == null);
    final yClean = (range.startY == null) == (range.endY == null);
    if (!xClean || !yClean) return null;
    final hasX = range.startX != null;
    final hasY = range.startY != null;
    if (hasX == hasY) return null;
    return hasY ? AnnotationAxis.y : AnnotationAxis.x;
  }

  List<_SourceRow> _synthesiseRows(List<ChartSeries> series, int rowCount) {
    final rows = <_SourceRow>[];
    for (var index = 0; index < rowCount; index++) {
      final numbers = List<double>.filled(_numberSlots, 0);
      final strings = List<String>.filled(_stringSlots, '');
      final stamps = List<DateTime?>.filled(_stampSlots, null);
      rows.add(_SourceRow(numbers, strings, stamps));
    }
    // Slot 0 always holds the shared x.
    for (var index = 0; index < rowCount; index++) {
      rows[index].numbers[0] = series.first.points[index].x;
    }
    return rows;
  }

  /// Fills the synthesised rows from the captured points, using the field
  /// plan built while planning the geometries.
  void _fillRows(List<_SourceRow> rows, List<_GeometryPlan> geometries) {
    for (final plan in geometries) {
      final series = plan.series;
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        switch (series) {
          case CandlestickChartSeries():
            final point = series.candles[index];
            row.numbers[plan.accessors['open']!.slot] = point.open;
            row.numbers[plan.accessors['high']!.slot] = point.high;
            row.numbers[plan.accessors['low']!.slot] = point.low;
            row.numbers[plan.accessors['close']!.slot] = point.close;
            final stamp = plan.accessors['timestamp'];
            if (stamp != null) row.stamps[stamp.slot] = point.timestamp;
          case ScatterChartSeries():
            final point = series.points[index];
            row.numbers[plan.accessors['y']!.slot] = point.y;
            _assign(row, plan, 'size', point.magnitude);
            _assign(row, plan, 'color', point.colorValue);
            _assign(row, plan, 'opacity', point.opacityValue);
            final category = plan.accessors['category'];
            if (category != null) {
              row.strings[category.slot] = point.categoryValue ?? '';
            }
          case ChartSeries():
            row.numbers[plan.accessors['y']!.slot] = series.points[index].y;
        }
      }
    }
  }

  void _assign(_SourceRow row, _GeometryPlan plan, String role, double? value) {
    final field = plan.accessors[role];
    if (field != null && value != null) row.numbers[field.slot] = value;
  }

  // =========================================================================
  // Emission
  // =========================================================================

  String _emitBody({
    required List<_GeometryPlan> geometries,
    required bool transposed,
    required _Field xField,
    required List<_SourceRow> rows,
  }) {
    final writer = DartSourceWriter();
    _emitRowClass(writer);
    writer.writeLine();
    _emitRows(writer, rows);
    writer.writeLine();
    _emitChain(
      writer,
      geometries: geometries,
      transposed: transposed,
      xField: xField,
    );
    return writer.toString();
  }

  void _emitRowClass(DartSourceWriter writer) {
    final className = options.rowClassName;
    writer.writeLine(
      '/// One row of the chart\'s data, synthesised from the captured series.',
    );
    writer.writeLine('///');
    writer.writeLine(
      '/// The chart document keeps the numbers each series was built from, not',
    );
    writer.writeLine(
      '/// the objects they came out of, so this class stands in for the row',
    );
    writer.writeLine('/// type the chart was originally authored over.');
    writer.writeLine('class $className {');
    writer.indented(() {
      writer.writeLine('const $className({');
      writer.indented(() {
        for (final field in _fields) {
          writer.writeLine('required this.${field.name},');
        }
      });
      writer.writeLine('});');
      writer.writeLine();
      for (final field in _fields) {
        writer.writeLine('final ${field.typeName} ${field.name};');
      }
    });
    writer.writeLine('}');
  }

  void _emitRows(DartSourceWriter writer, List<_SourceRow> rows) {
    final className = options.rowClassName;
    writer.writeLine(
      'final List<$className> ${options.rowsVariableName} = <$className>[',
    );
    writer.indented(() {
      if (_omitData) {
        writer.writeLine(
          '// ${rows.length} rows omitted. Supply this chart\'s data here.',
        );
        return;
      }
      for (final row in rows) {
        writer.writeLine('$className(');
        writer.indented(() {
          for (final field in _fields) {
            writer.namedArgument(field.name, _valueLiteral(row, field));
          }
        });
        writer.writeLine('),');
      }
    });
    writer.writeLine('];');
  }

  String _valueLiteral(_SourceRow row, _Field field) => switch (field.kind) {
    _FieldKind.number => DartSourceWriter.numberLiteral(
      row.numbers[field.slot],
    ),
    _FieldKind.string => DartSourceWriter.stringLiteral(
      row.strings[field.slot],
    ),
    _FieldKind.timestamp => _timestampLiteral(row.stamps[field.slot], field),
  };

  /// Writes a `DateTime.parse(...)` literal for a timestamp slot.
  ///
  /// A timestamp field is only synthesised once the partial-timestamp gate has
  /// proven every candle in its series carries one, so [stamp] is never null
  /// here. The explicit guard keeps a future regression from surfacing as an
  /// opaque null-check crash in the Workbench Source pane; it fails loudly with
  /// a named cause instead, in the same spirit as the `unreachable` guards.
  static String _timestampLiteral(DateTime? stamp, _Field field) {
    if (stamp == null) {
      throw StateError(
        'timestamp field "${field.name}" has no value at a row despite the '
        'partial-timestamp gate; this is a chart-grammar generator bug.',
      );
    }
    return 'DateTime.parse('
        '${DartSourceWriter.stringLiteral(stamp.toIso8601String())})';
  }

  void _emitChain(
    DartSourceWriter writer, {
    required List<_GeometryPlan> geometries,
    required bool transposed,
    required _Field xField,
  }) {
    writer.writeLine(
      'final ${options.variableName} = BravenChart.of('
      '${options.rowsVariableName})',
    );
    writer.indented(() {
      writer.indented(() {
        _emitX(writer, xField);
        for (final axis in configuration.axes) {
          _emitYAxis(writer, axis);
        }
        for (final plan in geometries) {
          _emitGeometry(writer, plan);
        }
        // Annotations are emitted in document order so a re-lowered chain
        // reproduces `configuration.annotations` index-for-index.
        for (final annotation in configuration.annotations) {
          _emitAnnotation(writer, annotation);
        }
        if (transposed) writer.writeLine('.transposed()');
        _emitTheme(writer);
        _emitInteraction(writer);
        _emitGrid(writer);
        _emitTitle(writer);
        _emitLegend(writer);
        writer.writeLine('.build();');
      });
    });
  }

  /// Dispatches a chart-level annotation to its chain verb. Every annotation
  /// reaching here passed the gate, so the wildcard is unreachable.
  void _emitAnnotation(DartSourceWriter writer, ChartAnnotation annotation) {
    switch (annotation) {
      case TrendAnnotation():
        _emitTrend(writer, annotation);
      case ThresholdAnnotation():
        _emitThreshold(writer, annotation);
      case RangeAnnotation():
        _emitBand(writer, annotation);
      case PointAnnotation():
        _emitPoint(writer, annotation);
      case ChartAnnotation():
        throw StateError(
          'unreachable: annotation "${annotation.id}" '
          '(${annotation.runtimeType}) passed the gate but has no chain verb',
        );
    }
  }

  void _emitX(DartSourceWriter writer, _Field xField) {
    final axis = configuration.xAxis;
    final label = axis.label;
    // `.x(label:)` is only faithful when the label is the ONLY thing set on
    // the X axis; anything else has to travel as a whole `.xAxis(...)`.
    if (axis == XAxisConfig(label: label)) {
      writer.writeLine(
        label == null
            ? '.x(${xField.accessor()})'
            : '.x(${xField.accessor()}, '
                  'label: ${DartSourceWriter.stringLiteral(label)})',
      );
      return;
    }
    writer.writeLine('.x(${xField.accessor()})');
    writer.writeLine('.xAxis(');
    writer.indented(() {
      writer.writeLine('XAxisConfig(');
      writer.indented(() => _config.emitXAxisFields(writer, axis));
      writer.writeLine('),');
    });
    writer.writeLine(')');
    _absorbConfigWarnings();
  }

  void _emitYAxis(DartSourceWriter writer, YAxisConfig axis) {
    writer.writeLine('.yAxis(');
    writer.indented(() {
      writer.writeLine('YAxisConfig.withId(');
      writer.indented(() {
        writer.namedArgument('id', DartSourceWriter.stringLiteral(axis.id));
        _config.emitYAxisFields(writer, axis);
      });
      writer.writeLine('),');
    });
    writer.writeLine(')');
    _absorbConfigWarnings();
  }

  void _emitGeometry(DartSourceWriter writer, _GeometryPlan plan) {
    final mark = plan.mark;
    final verb = switch (mark) {
      LineMark<_SourceRow>() => 'geomLine',
      AreaMark<_SourceRow>() => 'geomArea',
      BarMark<_SourceRow>() => 'geomBar',
      ScatterMark<_SourceRow>() => 'geomPoint',
      CandlestickMark<_SourceRow>() => 'geomCandlestick',
      TrendMark<_SourceRow>() => 'trend',
      // Reference marks lower to annotations and are emitted as their own chain
      // verbs, never through _emitGeometry, which only ever sees a geometry plan.
      ThresholdMark<_SourceRow>() ||
      BandMark<_SourceRow>() ||
      PointMark<_SourceRow>() => throw StateError(
        'unreachable: a reference mark reached _emitGeometry',
      ),
    };
    writer.writeLine('.$verb(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(mark.id!));
      switch (mark) {
        case CandlestickMark<_SourceRow>():
          for (final role in const ['open', 'high', 'low', 'close']) {
            writer.namedArgument(role, plan.accessors[role]!.accessor());
          }
          final stamp = plan.accessors['timestamp'];
          if (stamp != null) {
            writer.namedArgument('timestamp', stamp.accessor());
          }
        case _:
          writer.namedArgument('y', plan.accessors['y']!.accessor());
      }
      _optionalString(writer, 'name', mark.name);
      _optionalColor(writer, 'color', mark.color);
      switch (mark) {
        case LineMark<_SourceRow>():
          _optionalNumber(writer, 'strokeWidth', mark.strokeWidth);
          _optionalNumberList(writer, 'dashPattern', mark.dashPattern);
          if (mark.interpolation != null) {
            writer.namedArgument(
              'interpolation',
              'LineInterpolation.${mark.interpolation!.name}',
            );
          }
          _emitDataPointMarkers(
            writer,
            showDataPointMarkers: mark.showDataPointMarkers,
            dataPointLabels: mark.dataPointLabels,
          );
        case AreaMark<_SourceRow>():
          _optionalNumber(writer, 'baseline', mark.baseline);
          _optionalNumber(writer, 'fillOpacity', mark.fillOpacity);
          _optionalNumber(writer, 'strokeWidth', mark.strokeWidth);
          _optionalNumberList(writer, 'dashPattern', mark.dashPattern);
          if (mark.interpolation != null) {
            writer.namedArgument(
              'interpolation',
              'LineInterpolation.${mark.interpolation!.name}',
            );
          }
          _emitDataPointMarkers(
            writer,
            showDataPointMarkers: mark.showDataPointMarkers,
            dataPointLabels: mark.dataPointLabels,
          );
        case BarMark<_SourceRow>():
          _optionalNumber(writer, 'barWidthPercent', mark.barWidthPercent);
          _optionalNumber(writer, 'barWidthPixels', mark.barWidthPixels);
          _optionalNumber(writer, 'barGap', mark.barGap);
          if (mark.layoutMode != null) {
            writer.namedArgument(
              'layoutMode',
              'BarLayoutMode.${mark.layoutMode!.name}',
            );
          }
          _optionalString(writer, 'groupId', mark.groupId);
          _optionalNumber(writer, 'baselineValue', mark.baselineValue);
          final labelStyle = mark.labelStyle;
          if (labelStyle != null && labelStyle != const BarLabelStyle()) {
            _config.emitBarLabelStyle(writer, labelStyle);
            _absorbConfigWarnings();
          }
        case ScatterMark<_SourceRow>():
          _emitScatterChannels(writer, plan, mark);
        case CandlestickMark<_SourceRow>():
          break;
        case TrendMark<_SourceRow>():
          break;
        case ThresholdMark<_SourceRow>() ||
            BandMark<_SourceRow>() ||
            PointMark<_SourceRow>():
          break; // unreachable: the verb switch above already threw.
      }
      _optionalString(writer, 'yAxisId', mark.yAxisId);
    });
    writer.writeLine(')');
  }

  /// Emits the shared line/area data-point marker fields: the boolean toggle
  /// when set, and the label configuration when present. Both default to unset
  /// on the mark, so a V1 series (markers off, no labels) emits neither.
  void _emitDataPointMarkers(
    DartSourceWriter writer, {
    required bool? showDataPointMarkers,
    required DataPointLabelConfig? dataPointLabels,
  }) {
    if (showDataPointMarkers ?? false) {
      writer.namedArgument('showDataPointMarkers', 'true');
    }
    if (dataPointLabels != null) {
      _config.emitDataPointLabels(writer, dataPointLabels);
      _absorbConfigWarnings();
    }
  }

  void _emitScatterChannels(
    DartSourceWriter writer,
    _GeometryPlan plan,
    ScatterMark<_SourceRow> mark,
  ) {
    void channel(String argument, String role) {
      final field = plan.accessors[role];
      if (field == null) return;
      writer.namedArgument(argument, 'Channel(${field.accessor()})');
    }

    channel('size', 'size');
    if (mark.sizeEncoding != null) {
      _config.emitScatterSizeEncoding(writer, mark.sizeEncoding!);
    }
    channel('colorBy', 'color');
    if (mark.colorEncoding != null) {
      _config.emitScatterColorEncoding(writer, mark.colorEncoding!);
    }
    channel('opacityBy', 'opacity');
    if (mark.opacityEncoding != null) {
      _config.emitScatterOpacityEncoding(writer, mark.opacityEncoding!);
    }
    final category = plan.accessors['category'];
    if (category != null) {
      final label = mark.categoryBy?.label;
      writer.namedArgument(
        'categoryBy',
        label == null
            ? 'CategoryChannel(${category.accessor()})'
            : 'CategoryChannel(${category.accessor()}, '
                  'label: ${DartSourceWriter.stringLiteral(label)})',
      );
      _config.emitScatterCategoryStyles(writer, 'categories', mark.categories);
    }
    _optionalNumber(writer, 'markerRadius', mark.markerRadius);
    if (mark.markerShape != null) {
      writer.namedArgument(
        'markerShape',
        'SeriesMarkerShape.${mark.markerShape!.name}',
      );
    }
    if (mark.markerStyle != null) {
      _config.emitScatterMarkerStyle(writer, 'markerStyle', mark.markerStyle!);
    }
    _absorbConfigWarnings();
  }

  void _emitTrend(DartSourceWriter writer, TrendAnnotation annotation) {
    writer.writeLine('.trend(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(annotation.id));
      writer.namedArgument(
        'of',
        DartSourceWriter.stringLiteral(annotation.seriesId),
      );
      writer.namedArgument('method', 'TrendType.${annotation.trendType.name}');
      if (annotation.windowSize != null) {
        writer.namedArgument('windowSize', '${annotation.windowSize}');
      }
      _optionalString(writer, 'name', annotation.label);
      _optionalColor(writer, 'color', annotation.lineColor);
      if (annotation.showConfidenceBand) {
        writer.namedArgument('showConfidenceBand', 'true');
      }
      _optionalNumber(writer, 'lineWidth', annotation.lineWidth);
      _optionalNumberList(writer, 'dashPattern', annotation.dashPattern);
    });
    writer.writeLine(')');
  }

  void _emitThreshold(DartSourceWriter writer, ThresholdAnnotation annotation) {
    writer.writeLine('.threshold(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(annotation.id));
      writer.namedArgument(
        'value',
        DartSourceWriter.numberLiteral(annotation.value),
      );
      writer.namedArgument('axis', 'AnnotationAxis.${annotation.axis.name}');
      _optionalString(writer, 'label', annotation.label);
      _optionalColor(writer, 'color', annotation.lineColor);
      _optionalNumber(writer, 'strokeWidth', annotation.lineWidth);
      _optionalNumberList(writer, 'dashPattern', annotation.dashPattern);
    });
    writer.writeLine(')');
  }

  void _emitBand(DartSourceWriter writer, RangeAnnotation annotation) {
    // The gate proved this is a clean 1-D band, so an axis is always resolved.
    final axis = _bandAxis(annotation)!;
    final isY = axis == AnnotationAxis.y;
    writer.writeLine('.band(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(annotation.id));
      writer.namedArgument(
        'start',
        DartSourceWriter.numberLiteral(
          (isY ? annotation.startY : annotation.startX)!,
        ),
      );
      writer.namedArgument(
        'end',
        DartSourceWriter.numberLiteral(
          (isY ? annotation.endY : annotation.endX)!,
        ),
      );
      writer.namedArgument('axis', 'AnnotationAxis.${axis.name}');
      _optionalString(writer, 'label', annotation.label);
      _optionalColor(writer, 'color', annotation.fillColor);
    });
    writer.writeLine(')');
  }

  void _emitPoint(DartSourceWriter writer, PointAnnotation annotation) {
    writer.writeLine('.pointAt(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(annotation.id));
      writer.namedArgument(
        'seriesId',
        DartSourceWriter.stringLiteral(annotation.seriesId),
      );
      writer.namedArgument('dataPointIndex', '${annotation.dataPointIndex}');
      _optionalString(writer, 'label', annotation.label);
      _optionalColor(writer, 'color', annotation.markerColor);
      _optionalNumber(writer, 'markerSize', annotation.markerSize);
      writer.namedArgument(
        'markerShape',
        'MarkerShape.${annotation.markerShape.name}',
      );
    });
    writer.writeLine(')');
  }

  void _emitTheme(DartSourceWriter writer) {
    final reference = snapshot.document.theme.reference;
    final expression = ChartThemeDocumentCodec.builtInThemeMember(reference);
    if (expression != null) {
      writer.writeLine('.theme($expression)');
      return;
    }
    if (reference != null) {
      _warn(
        code: ChartSourceWarningCodes.unsupportedPortableValue,
        message:
            'Theme reference "$reference" is host-owned and was omitted. '
            'Provide the matching ChartTheme with .theme(...) from your '
            'application.',
        path: r'$.theme.reference',
      );
      return;
    }
    writer.writeLine('.theme(');
    writer.indented(() {
      writer.writeLine('ChartTheme(');
      writer.indented(
        () => _config.emitResolvedThemeFields(writer, configuration.theme),
      );
      writer.writeLine('),');
    });
    writer.writeLine(')');
    _absorbConfigWarnings();
  }

  void _emitInteraction(DartSourceWriter writer) {
    final interaction = configuration.interaction;
    if (interaction == const InteractionConfig()) return;
    writer.writeLine('.interaction(');
    writer.indented(() {
      writer.writeLine('InteractionConfig(');
      writer.indented(() => _config.emitInteractionFields(writer, interaction));
      writer.writeLine('),');
    });
    writer.writeLine(')');
    _absorbConfigWarnings();
  }

  /// Emits `.grid(GridConfig(...))`, but only when the grid differs from the
  /// default. A default grid is reproduced by carrying none — `BravenChartPlus`
  /// resolves an unset grid to exactly `const GridConfig()` — so the verb is
  /// omitted, exactly as `_emitInteraction` omits a default interaction. Only
  /// the fields that differ from their defaults are written, so re-lowering the
  /// chain reconstructs the same `GridConfig`.
  void _emitGrid(DartSourceWriter writer) {
    final grid = configuration.grid;
    if (grid == const GridConfig() && !options.includeDefaultValues) return;
    const defaults = GridConfig();
    void valueIf(String name, Object value, Object defaultValue) {
      if (options.includeDefaultValues || value != defaultValue) {
        writer.namedArgument(name, '$value');
      }
    }

    writer.writeLine('.grid(');
    writer.indented(() {
      writer.writeLine('GridConfig(');
      writer.indented(() {
        valueIf('horizontal', grid.horizontal, defaults.horizontal);
        valueIf('vertical', grid.vertical, defaults.vertical);
        _optionalColor(writer, 'horizontalColor', grid.horizontalColor);
        _optionalColor(writer, 'verticalColor', grid.verticalColor);
        if (options.includeDefaultValues ||
            grid.horizontalStrokeWidth != defaults.horizontalStrokeWidth) {
          writer.namedArgument(
            'horizontalStrokeWidth',
            DartSourceWriter.numberLiteral(grid.horizontalStrokeWidth),
          );
        }
        if (options.includeDefaultValues ||
            grid.verticalStrokeWidth != defaults.verticalStrokeWidth) {
          writer.namedArgument(
            'verticalStrokeWidth',
            DartSourceWriter.numberLiteral(grid.verticalStrokeWidth),
          );
        }
      });
      writer.writeLine('),');
    });
    writer.writeLine(')');
  }

  /// Emits `.title(title, subtitle: subtitle)` when a title is set. A subtitle
  /// with no title cannot reach this point: it is refused by the chart-option
  /// gate, because the verb can only attach a subtitle to a title.
  void _emitTitle(DartSourceWriter writer) {
    final title = configuration.title;
    if (title == null) return;
    writer.writeLine('.title(');
    writer.indented(() {
      writer.writeLine('${DartSourceWriter.stringLiteral(title)},');
      _optionalString(writer, 'subtitle', configuration.subtitle);
    });
    writer.writeLine(')');
  }

  /// Emits `.legend(false)` only when the legend is hidden; a shown legend is
  /// the chart default and needs no verb.
  void _emitLegend(DartSourceWriter writer) {
    if (configuration.showLegend) return;
    writer.writeLine('.legend(false)');
  }

  // =========================================================================
  // Small emission helpers
  // =========================================================================

  void _optionalString(DartSourceWriter writer, String name, String? value) {
    if (value == null) return;
    writer.namedArgument(name, DartSourceWriter.stringLiteral(value));
  }

  void _optionalNumber(DartSourceWriter writer, String name, num? value) {
    if (value == null) return;
    writer.namedArgument(name, DartSourceWriter.numberLiteral(value));
  }

  void _optionalColor(DartSourceWriter writer, String name, Color? value) {
    if (value == null) return;
    writer.namedArgument(name, DartSourceWriter.colorLiteral(value));
  }

  void _optionalNumberList(
    DartSourceWriter writer,
    String name,
    List<double>? values,
  ) {
    if (values == null) return;
    writer.namedArgument(
      name,
      '<double>[${values.map(DartSourceWriter.numberLiteral).join(', ')}]',
    );
  }

  // =========================================================================
  // Diagnostics
  // =========================================================================

  void _captureKnownLimitations() {
    if (_omitData) {
      _warn(
        code: ChartSourceWarningCodes.dataOmitted,
        message:
            '${snapshot.document.pointCount} points omitted because '
            'maxInlinePoints is ${options.maxInlinePoints}. Supply '
            'application data in the generated row list.',
        path: r'$.series[*].data',
      );
    }
    if (snapshot.document.interaction.requiredBindings.isNotEmpty) {
      final bindings = snapshot.document.interaction.requiredBindings.toList()
        ..sort();
      _warn(
        code: ChartSourceWarningCodes.runtimeValueOmitted,
        message:
            'Runtime interaction bindings omitted: ${bindings.join(', ')}. '
            'Provide these callbacks from your application.',
        path: r'$.interaction.requiredBindings',
      );
    }
  }

  /// Copies warnings raised by the shared config emitter into this result.
  void _absorbConfigWarnings() {
    for (final warning in _config.emittedWarnings) {
      if (_warnings.contains(warning)) continue;
      _warnings.add(warning);
    }
  }

  void _warn({required String code, required String message, String? path}) {
    final warning = ChartSourceWarning(
      code: code,
      message: message,
      path: path,
    );
    if (_warnings.contains(warning)) return;
    _warnings.add(warning);
  }

  /// Breaks a long diagnostic into comment-width lines.
  static List<String> _wrapComment(String message, {int width = 72}) {
    final lines = <String>[];
    final buffer = StringBuffer();
    for (final word in message.split(' ')) {
      if (buffer.isEmpty) {
        buffer.write(word);
      } else if (buffer.length + 1 + word.length <= width) {
        buffer.write(' $word');
      } else {
        lines.add(buffer.toString());
        buffer.clear();
        buffer.write(word);
      }
    }
    if (buffer.isNotEmpty) lines.add(buffer.toString());
    return lines;
  }
}
