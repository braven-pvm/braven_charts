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
/// | a pie, donut, concentric-donut or polar-column family | emitted as geomPie / geomDonut(ring:) / geomPolar, carrying the series style, unit, selection and slice configs |
/// | a layered/grouped/stacked polar composition | emitted as ONE geomPolar per series over a shared category field |
/// | a customised PolarChartConfig | emitted as .polarConfig(...) |
/// | a polar series carrying per-category column colors, targets or intervals, or the rose preset | emitted as geomPolar row-channels + `rose: true` |
/// | a non-default ConcentricDonutConfig | emitted as geomDonut(concentric: ...) |
/// | a radial-bar, gauge or range-area family (no grammar geometry) | blocked — no mark reverses it |
/// | a concentric composition whose ring series ids do not follow `'<markId>-<ring>'` | emitted as `geomDonut(ringIds: {...})` — `DonutMark` carries an explicit ring-key→series-id map, consulted ONLY when the id pattern fails to recover a markId, so a conforming composition emits unchanged |
/// | a concentric composition whose rings are unnamed or share a name | blocked — the ring key IS the series name, so no `ring:` channel could bucket those rows apart |
/// | a concentric composition whose rings DIVERGE in `donutStyle`, `selectionStyle`, `unit`, `sliceRadiusConfig` or `sliceGroupingConfig`, or in which ANY ring carries a series `color` | blocked — `DonutMark` holds ONE of each for the whole composition and `_lowerConcentricRings` stamps it onto every ring, and unlike the single-donut `_lowerDonut` beside it never passes `mark.color` at all. Sharing a NON-DEFAULT value is fine; divergence is not, and no ring may carry a series colour even when every ring carries the same one. These reach the author through the catch-all row below rather than a reason of their own — a gap, since an author can hit them from ordinary config-form Dart |
/// | a pie or donut carrying per-slice colors (`sliceColors`) | emitted as a `sliceColor:` row channel — `PieMark`/`DonutMark` carry one of their own, mirroring `PolarMark.columnColor`, and a concentric composition resolves it per ring bucket |
/// | a pie or donut point whose `PointStyle` carries MORE than a color and a size | blocked, naming the family's reversible set — `scatterMarkerShape` / `scatterMarkerStyle` have no radial channel, and a bare `const PointStyle()` reverses to null, so both stay honest refusals rather than silent drops |
/// | a donut center setting `labelStyle` or `valueStyle` | emitted as `center: DonutCenterContent(...)` — the captured center rides the mark VERBATIM and is written by the config emitter's own center renderer, so both styles survive |
/// | a donut center setting `valueFormatter` | emitted with a `// valueFormatter:` placeholder and a runtime-value-omitted warning, exactly as the config form does — the chain is real but not complete |
/// | a concentric composition whose rings carry DIFFERENT `dataLabels` | emitted as `geomDonut(dataLabelsByRing: {...})` — the mark carries ring 0's config as the base `dataLabels:` and only the rings that DIFFER from it are projected, so a uniform composition emits unchanged; inside the map an entry equal to the family default is a real override and is written |
/// | polar series whose category domains differ | blocked — N geomPolar marks read ONE row list |
/// | series whose x domains differ | blocked — one row list plus TOTAL accessors cannot express them |
/// | a partially populated scatter channel | blocked — a `Channel` accessor is `num Function(T)`, so it cannot return "no value" |
/// | mixed bar orientations | blocked — `.transposed()` is a whole-chart operation |
/// | a chart-level trend, threshold, range or point annotation | emitted as .trend/.threshold/.band/.pointAt |
/// | any other annotation (text, pin, chord, error-bar, legend, a 2-D/half-open range, or ANY series-level annotation) | blocked and LISTED, never dropped |
/// | a chart-level option `BravenPlot` does not forward — `showToolbar`, `interactiveAnnotations`, `maxAxesPerSide`, the axis-swap / normalization knobs, width/height, background, `legendStyle`, `radialBarChartConfig`, or a subtitle with no title | blocked and named. The title, subtitle, grid and legend toggle ARE forwarded and emit as `.title(...)` / `.grid(...)` / `.legend(...)` |
/// | anything else the reconstructed chain would not reproduce | blocked by the round-trip proof below |
/// | a runtime interaction binding | emitted with a warning, exactly as the config form does |
/// | data above `maxInlinePoints` | emitted with a placeholder row list and a warning, exactly as the config form does |
///
/// ## The round-trip proof, and exactly what it proves
///
/// Before emitting anything, the generator BUILDS THE SPEC IT IS ABOUT TO
/// WRITE — over an internal row type carrying the same synthesised values —
/// lowers it with the real `PlotSpecLowering`, and compares the resulting
/// `ChartSeries`, `ChartAnnotation`s, Y-axis configs AND the X axis, theme and
/// interaction to the ones the document hydrated to. Anything that does not
/// compare equal is refused.
///
/// What that buys is precise, and overstating it would be its own dishonesty.
/// The proof covers the PLAN and the RE-LOWERED SERIES AND ANNOTATIONS: every
/// channel, every accessor, every value the emitter reconstructed is read back
/// out of the synthesised rows by real lowering, and every reference mark is
/// turned back into a `ChartAnnotation`, so a mark that fails to carry
/// something produces a divergent series or annotation and an honest refusal —
/// without the emitter having to enumerate every option a V1 mark happens not
/// to carry.
///
/// It does NOT cover the emitted CONFIG LITERALS. Anything the grammar carries
/// verbatim — the plot-level options a `PlotSpec` forwards (`xAxis`, `theme`,
/// `interaction`, `grid`, `title`, `subtitle`, `showLegend`, and for radial
/// `PlotSpec.polar`), `DonutMark.concentric`, a mark's style/selection/label
/// configs — is handed to the proof spec as the CAPTURED INSTANCE, and lowering
/// hands that same instance straight back, so the comparison is an instance
/// against itself. Those comparisons are regression TRIPWIRES on lowering (they
/// fire if lowering ever stops forwarding a value, which is precisely what it
/// did for the polar config before `.polarConfig(...)` existed), not proofs
/// about the `.xAxis(...)` / `.grid(...)` / `.title(...)` / `.polarConfig(...)`
/// / `geomDonut(concentric: ...)` TEXT — deleting one of those emissions
/// produces zero refusals, and only the emitted-text assertions in the emitter
/// tests fail.
/// The literals are held to their own three guards instead: they are written
/// by the config emitter's own shared renderers through public seams (so the
/// CONFIG and GRAMMAR forms cannot disagree), `test/meta/source_emitter_drift_test.dart`
/// fails on any field neither form renders, and the emitter tests assert the
/// emitted text field by field.
///
/// So "the generator emitted a chain" means "this chain re-lowers to this
/// chart's series and annotations"; "this chain's config literals are right" is
/// what the shared renderer, the drift gate and the emitted-text assertions
/// mean.
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
import '../grammar/series_axis_unbinding.dart';
import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/concentric_donut_config.dart';
import '../models/data_point_label_config.dart';
import '../models/donut_chart_config.dart';
import '../models/donut_chart_series.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/pie_chart_config.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';
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
  const _SourceRow(
    this.numbers,
    this.strings,
    this.stamps,
    this.optionalNumbers,
    this.colors,
  );

  final List<double> numbers;
  final List<String> strings;
  final List<DateTime?> stamps;

  /// Slots for channels whose ABSENCE is meaningful — a polar category with no
  /// target or no interval. A synthesised 0 there is a real value on the radial
  /// scale and would draw a marker the captured chart does not have, so these
  /// carry null instead.
  final List<double?> optionalNumbers;

  /// Slots for per-row colour overrides (a polar column's `columnColors`).
  final List<Color?> colors;
}

enum _FieldKind { number, string, timestamp, optionalNumber, color }

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
    _FieldKind.optionalNumber => 'double?',
    _FieldKind.color => 'Color?',
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

/// A planned donut center together with the document site it was CAPTURED
/// from.
///
/// The two travel as one because the site is not decorative: when a center's
/// `valueFormatter` is a live callback the emitter writes a placeholder and a
/// `runtimeValueOmitted` warning, and that warning quotes this path. The two
/// donut shapes capture their center from genuinely different places — a plain
/// donut and a single-ring collapse from the series' own
/// `style.centerContent`, a MULTI-RING concentric composition from the
/// plot-level `configuration.concentricDonut.centerContent`, which no series
/// carries at all. Letting the emitter guess produced a warning that pointed
/// the workbench at a field the document did not have, and disagreed with what
/// the config form calls the very same object.
class _PlannedCenter {
  const _PlannedCenter(this.content, this.message, this.path);

  /// The center a plain donut, or a concentric composition that collapsed to a
  /// single ring, carries on series [seriesIndex] itself.
  factory _PlannedCenter.onSeries(DonutCenterContent content, int seriesIndex) {
    final site = ChartConfigDartEmitter.donutCenterWarningSite(seriesIndex);
    return _PlannedCenter(content, site.message, site.path);
  }

  /// The shared center a multi-ring concentric composition carries on its
  /// plot-level [ConcentricDonutConfig].
  factory _PlannedCenter.onConcentricConfig(DonutCenterContent content) {
    const site = ChartConfigDartEmitter.concentricCenterWarningSite;
    return _PlannedCenter(content, site.message, site.path);
  }

  final DonutCenterContent content;

  /// The wording and document path the omitted-formatter warning quotes — the
  /// same pair the config form reports for this object.
  final String message;
  final String path;
}

/// Which radial geometry a captured chart reverses to.
///
/// The polar family is NOT here: it is the one radial family whose plot may
/// carry several geoms (a layered/grouped/stacked composition), so it is
/// planned by [_PolarChartPlan] rather than the single-mark [_RadialPlan].
enum _RadialKind { pie, donut, concentric }

/// The plan for a RADIAL chain: the single radial mark the round-trip proof
/// lowers, the synthesised rows, and the fields whose accessors the emitter
/// writes. A radial spec carries exactly one geometry, so — unlike the
/// Cartesian [_GeometryPlan] list — this is a single object.
class _RadialPlan {
  _RadialPlan({
    required this.kind,
    required this.mark,
    required this.rows,
    required this.verb,
    required this.category,
    required this.value,
    this.radius,
    this.ring,
    this.sliceColor,
    this.center,
  });

  final _RadialKind kind;
  final RadialMark<_SourceRow> mark;
  final List<_SourceRow> rows;

  /// The chain verb: `geomPie` / `geomDonut` / `geomPolar`.
  final String verb;

  final _Field category;
  final _Field value;

  /// Optional variable-radius field (a second metric on each slice/column).
  final _Field? radius;

  /// Concentric-ring grouping field, present only for a `geomDonut(ring:)`.
  final _Field? ring;

  /// Optional per-slice colour-override field, present only when some captured
  /// point carries a colour. A row whose category has no override writes null.
  final _Field? sliceColor;

  /// The donut center summary to emit — with the site its formatter warning
  /// names — or null when there is none.
  final _PlannedCenter? center;
}

/// One polar series of a polar plan: the mark the proof lowers plus the value
/// field its `value:` accessor reads. The category field is shared by every
/// series and lives on the [_PolarChartPlan].
class _PolarSeriesPlan {
  _PolarSeriesPlan({
    required this.value,
    required this.mark,
    this.columnColor,
    this.target,
    this.intervalLow,
    this.intervalHigh,
  });

  final _Field value;

  /// Per-category column colour, present only when the series carries one.
  final _Field? columnColor;

  /// Per-category absolute target, present only when the series carries any.
  final _Field? target;

  /// The two interval bounds, both present or both absent.
  final _Field? intervalLow;
  final _Field? intervalHigh;

  final PolarMark<_SourceRow> mark;
}

/// The plan for a POLAR chain: N `geomPolar` marks over ONE row list, plus the
/// plot-level configuration `.polarConfig(...)` carries.
///
/// A polar composition is the one radial shape with several geoms in a plot.
/// Every series shares the category domain — the render and hydration layers
/// both enforce it through `PolarColumnComposition.validate` — so one shared
/// category field plus one value field per series reverses it exactly.
class _PolarChartPlan {
  _PolarChartPlan({
    required this.rows,
    required this.category,
    required this.series,
    required this.config,
  });

  final List<_SourceRow> rows;

  /// The category accessor EVERY polar mark reads.
  final _Field category;

  final List<_PolarSeriesPlan> series;

  /// The captured plot-level polar configuration, carried onto the proof spec
  /// so the re-lowered plot reproduces it instead of defaulting.
  final PolarChartConfig config;
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
  var _optionalNumberSlots = 0;
  var _colorSlots = 0;

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

    // The header is built after the chain, so the material import can hide the
    // names the chain actually made ambiguous.
    final writer = DartSourceWriter();
    if (body != null && options.includeImports) {
      writer.writeLine("import 'package:braven_charts/braven_charts.dart';");
      writer.writeLine(DartSourceWriter.materialImport(body));
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
      if (!_isEmittableFamily(item)) {
        unsupportedFamilies.add('${item.id} (${item.runtimeType})');
      }
    }
    if (unsupportedFamilies.isNotEmpty) {
      block(
        'Grammar chain not emitted: the grammar layer has geometries for line, '
        'area, bar, scatter, candlestick, pie, donut and polar-column series, '
        'but not for these — a radial-bar, gauge or range-area family has no '
        'mark to reverse it: ${unsupportedFamilies.join(', ')}.',
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

    // ---- 2b. radial families take the dedicated radial path -------------
    // A radial spec has its own coordinate system: exactly one radial geom, no
    // Cartesian axis/grid/transpose option. It cannot share the per-series
    // shared-x reversal the Cartesian arms below use, so it branches here.
    if (series.any(_isRadialFamily)) {
      return _tryEmitRadialChain(series, block);
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
  // Radial reversal
  // =========================================================================

  /// Reverses a RADIAL chart (pie / donut / concentric-donut / polar-column)
  /// into a `geomPie` / `geomDonut(ring:)` / `geomPolar` chain, proving fidelity
  /// against the real radial lowering before emitting anything — exactly as the
  /// Cartesian path does, but over the radial branch of `spec.lower()`.
  String? _tryEmitRadialChain(
    List<ChartSeries> series,
    void Function(String message, {String? path}) block,
  ) {
    _usedNames.add(options.rowsVariableName);
    // The polar family takes its own path: it is the one radial family a plot
    // may hold several geoms of, and the only one with a plot-level config the
    // chain sets with a spec verb rather than a mark argument.
    if (series.isNotEmpty &&
        series.every((item) => item is PolarColumnChartSeries)) {
      return _tryEmitPolarChain(series.cast<PolarColumnChartSeries>(), block);
    }
    final plan = _planRadial(series, block);
    if (plan == null) return null;

    // The radial proof spec MUST null the Cartesian axis/grid options and stay
    // untransposed, or radial lowering throws `axisOptionOnRadialSpec`.
    final spec = PlotSpec<_SourceRow>(
      data: plan.rows,
      marks: <Mark<_SourceRow>>[plan.mark],
      transposed: false,
      theme: configuration.theme,
      interaction: configuration.interaction,
      xAxis: null,
      yAxes: const <YAxisConfig>[],
      grid: null,
      title: configuration.title,
      subtitle: configuration.subtitle,
      showLegend: configuration.showLegend,
    );
    final LoweredPlot lowered;
    try {
      lowered = spec.lower();
    } on GrammarSpecException catch (error) {
      block(
        'Grammar chain not emitted: the reconstructed radial specification was '
        'rejected by the grammar layer — ${error.message}',
        path: r'$.series',
      );
      return null;
    }
    final mismatch = _firstRadialMismatch(lowered);
    if (mismatch != null) {
      block(
        'Grammar chain not emitted: the reconstructed chain does not reproduce '
        '${mismatch.subject} exactly, so writing it would hand back a '
        'different chart. ${mismatch.detail}',
        path: r'$.series',
      );
      return null;
    }

    _captureKnownLimitations();
    return _emitRadialBody(plan);
  }

  /// Reverses a POLAR-COLUMN chart — one series or a layered/grouped/stacked
  /// composition of several — into N `geomPolar` marks plus the plot-level
  /// `.polarConfig(...)`, proving fidelity the same way [_tryEmitRadialChain]
  /// does.
  ///
  /// The proof spec carries the CAPTURED `PolarChartConfig` on `PlotSpec.polar`,
  /// so the re-lowered plot reproduces a customised pane / axis / composition
  /// instead of defaulting — which is what turned a customised config from an
  /// honest refusal into an emitted chain.
  String? _tryEmitPolarChain(
    List<PolarColumnChartSeries> series,
    void Function(String message, {String? path}) block,
  ) {
    final plan = _planPolarChart(series, block);
    if (plan == null) return null;

    // As for the other radial families: the Cartesian axis/grid options MUST be
    // null and the spec untransposed, or radial lowering throws
    // `axisOptionOnRadialSpec`.
    final spec = PlotSpec<_SourceRow>(
      data: plan.rows,
      marks: <Mark<_SourceRow>>[for (final item in plan.series) item.mark],
      transposed: false,
      theme: configuration.theme,
      interaction: configuration.interaction,
      xAxis: null,
      yAxes: const <YAxisConfig>[],
      grid: null,
      title: configuration.title,
      subtitle: configuration.subtitle,
      showLegend: configuration.showLegend,
      polar: plan.config,
    );
    final LoweredPlot lowered;
    try {
      lowered = spec.lower();
    } on GrammarSpecException catch (error) {
      block(
        'Grammar chain not emitted: the reconstructed radial specification was '
        'rejected by the grammar layer — ${error.message}',
        path: r'$.series',
      );
      return null;
    }
    final mismatch = _firstRadialMismatch(lowered);
    if (mismatch != null) {
      block(
        'Grammar chain not emitted: the reconstructed chain does not reproduce '
        '${mismatch.subject} exactly, so writing it would hand back a '
        'different chart. ${mismatch.detail}',
        path: r'$.series',
      );
      return null;
    }

    _captureKnownLimitations();
    return _emitPolarChartBody(plan);
  }

  /// Classifies [series] into one radial kind and builds its plan, or blocks
  /// and returns null when the shape is not one radial geometry.
  _RadialPlan? _planRadial(
    List<ChartSeries> series,
    void Function(String message, {String? path}) block,
  ) {
    if (series.every((item) => item is PieChartSeries)) {
      if (series.length != 1) {
        block(
          'Grammar chain not emitted: a pie chain expresses exactly one pie '
          'geometry, so ${series.length} pie series cannot be reversed to a '
          'single geomPie.',
          path: r'$.series',
        );
        return null;
      }
      return _planPie(series.single as PieChartSeries);
    }
    // An all-polar chart never reaches here: `_tryEmitRadialChain` routes it to
    // `_planPolarChart`, which reverses one geomPolar PER series.
    if (series.every((item) => item is DonutChartSeries)) {
      final donuts = series.cast<DonutChartSeries>();
      // `concentricDonutConfig != null` is the AUTHORITATIVE discriminator: the
      // forward path sets it ONLY inside `DonutMark.ring != null` lowering, so
      // its presence — not the series count — means a concentric composition
      // (the single-distinct-ring collapse carries a non-null config too).
      // That stays true because `geomDonut(concentric:)` REFUSES a ring-less
      // donut by name (`concentricConfigOnRinglessDonut`) rather than carrying
      // a config the composition-less family would never use. The document
      // path agrees: hydration rejects a config paired with fewer than two
      // donut series, so `_planConcentric` only ever sees a real composition
      // through the public entry point.
      if (configuration.concentricDonutConfig != null) {
        return _planConcentric(donuts, block);
      }
      if (donuts.length != 1) {
        block(
          'Grammar chain not emitted: ${donuts.length} donut series without a '
          'ConcentricDonutConfig is not a shape the grammar produces — a '
          'concentric composition always carries that config.',
          path: r'$.series',
        );
        return null;
      }
      return _planDonut(donuts.single);
    }
    block(
      'Grammar chain not emitted: a radial chain expresses ONE radial family — '
      'several geomPolar marks, or exactly one geomPie / geomDonut — and '
      'cannot mix radial families or combine a radial series with a Cartesian '
      'one: '
      '${series.map((item) => '${item.id} (${item.runtimeType})').join(', ')}.',
      path: r'$.series',
    );
    return null;
  }

  _RadialPlan _planPie(PieChartSeries series) {
    // EVERY field is allocated before the rows are synthesised: a row is sized
    // from the slot counts at the moment it is built, so a field added after
    // this point would index past the end of its slot list.
    final category = _addField('category', _FieldKind.string);
    final value = _addField('value', _FieldKind.number);
    final radius = _radialRadiusField([series]);
    final sliceColor = _radialSliceColorField([series]);
    final rows = _synthesiseRadialRows(series.points.length);
    _fillRadialRows(
      rows,
      series.points,
      category,
      value,
      radius,
      ring: null,
      sliceColor: sliceColor,
    );
    return _RadialPlan(
      kind: _RadialKind.pie,
      verb: 'geomPie',
      rows: rows,
      category: category,
      value: value,
      radius: radius,
      sliceColor: sliceColor,
      mark: PieMark<_SourceRow>(
        id: series.id,
        name: series.name,
        color: series.color,
        unit: series.unit,
        category: _string(category),
        value: _number(value),
        radius: radius == null ? null : _number(radius),
        sliceColor: sliceColor == null ? null : _color(sliceColor),
        // Carry the series' unit, slice styling, selection, data labels and the
        // slice-radius / grouping configs onto the mark so the round-trip proof
        // reproduces the whole pie (the lowering maps PieMark.style →
        // PieChartSeries.pieStyle, .selectionStyle → .selectionStyle,
        // .dataLabels → .dataLabels, .sliceRadiusConfig / .sliceGroupingConfig →
        // the series' own). A slice-radius formatter is a live callback: the
        // config objects round-trip by identity, but its emission is an honest
        // placeholder.
        style: series.pieStyle,
        selectionStyle: series.selectionStyle,
        dataLabels: series.dataLabels,
        sliceRadiusConfig: series.sliceRadiusConfig,
        sliceGroupingConfig: series.sliceGroupingConfig,
      ),
    );
  }

  _RadialPlan _planDonut(DonutChartSeries series) {
    // As for pie: every field is allocated BEFORE the rows are synthesised.
    final category = _addField('category', _FieldKind.string);
    final value = _addField('value', _FieldKind.number);
    final radius = _radialRadiusField([series]);
    final sliceColor = _radialSliceColorField([series]);
    final rows = _synthesiseRadialRows(series.points.length);
    _fillRadialRows(
      rows,
      series.points,
      category,
      value,
      radius,
      ring: null,
      sliceColor: sliceColor,
    );
    final center = _markCenter(series.centerContent, DonutCenterContent.hidden);
    // `_planRadial` reaches here only for a chart of exactly ONE donut series,
    // so this center really is `$.series[0].style.centerContent`.
    return _RadialPlan(
      kind: _RadialKind.donut,
      verb: 'geomDonut',
      rows: rows,
      category: category,
      value: value,
      radius: radius,
      sliceColor: sliceColor,
      center: center == null ? null : _PlannedCenter.onSeries(center, 0),
      mark: DonutMark<_SourceRow>(
        id: series.id,
        name: series.name,
        color: series.color,
        unit: series.unit,
        category: _string(category),
        value: _number(value),
        radius: radius == null ? null : _number(radius),
        sliceColor: sliceColor == null ? null : _color(sliceColor),
        // As for pie: carry the donut unit, styling, selection, data labels and
        // slice-radius / grouping configs so the whole donut round-trips
        // (DonutMark.style → DonutChartSeries.donutStyle, .selectionStyle →
        // .selectionStyle, .dataLabels → .dataLabels, the two slice configs →
        // the series' own; the center is already carried above).
        style: series.donutStyle,
        selectionStyle: series.selectionStyle,
        center: center,
        dataLabels: series.dataLabels,
        sliceRadiusConfig: series.sliceRadiusConfig,
        sliceGroupingConfig: series.sliceGroupingConfig,
      ),
    );
  }

  _RadialPlan? _planConcentric(
    List<DonutChartSeries> donuts,
    void Function(String message, {String? path}) block,
  ) {
    // The forward path ids each ring `'<markId>-<ringKey>'` and names it
    // `<ringKey>`. Recover that shared markId so the re-lowered ring ids
    // reproduce the captured ones.
    //
    // When the ids do NOT follow that pattern the chart is still a concentric
    // composition — it just chose its ids independently of its ring names,
    // which is what a config-authored chart usually does. The chain then names
    // every ring explicitly through `geomDonut(ringIds:)` and the markId is
    // synthesised, because with a full map it no longer reaches any series id.
    //
    // This branch is entered ONLY when the pattern fails, so a conforming
    // composition takes the original path untouched and its emitted text is
    // byte-identical to what it was before this channel existed.
    final recovered = _concentricMarkId(donuts);
    final Map<String, String>? explicitRingIds;
    if (recovered == null) {
      // The ring KEY is the series NAME — that is the value the `ring:` channel
      // returns and the map is keyed by — so a composition whose rings are
      // unnamed, or share a name, cannot be reversed to a ring channel at all:
      // its rows would bucket together into one ring. Refused by name, as
      // before, rather than renamed into something that emits.
      final keys = <String>[for (final donut in donuts) donut.name ?? ''];
      if (keys.any((key) => key.isEmpty) ||
          keys.toSet().length != keys.length) {
        block(
          'Grammar chain not emitted: a geomDonut(ring:) chain builds each ring '
          'from the value its ring channel returns and names the ring series '
          'after it, so every donut series in the composition needs a distinct, '
          'non-empty name. These do not: '
          '${donuts.map((donut) => '"${donut.id}" (name '
              '${donut.name == null ? 'unset' : '"${donut.name}"'})').join(', ')}.',
          path: r'$.series',
        );
        return null;
      }
      explicitRingIds = <String, String>{
        for (final donut in donuts) donut.name!: donut.id,
      };
    } else {
      explicitRingIds = null;
    }
    final markId = recovered ?? _synthesisedConcentricMarkId;
    // EVERY field must be allocated here, BEFORE `_synthesiseRadialRows`: the
    // rows below are sized from the current slot counts, so a field added
    // afterwards would throw a `RangeError` on the first row write.
    final ring = _addField('ring', _FieldKind.string);
    final category = _addField('category', _FieldKind.string);
    final value = _addField('value', _FieldKind.number);
    final radius = _radialRadiusField(donuts);
    final sliceColor = _radialSliceColorField(donuts);
    final totalRows = donuts.fold<int>(0, (sum, d) => sum + d.points.length);
    final rows = _synthesiseRadialRows(totalRows);
    // This loop is the concentric equivalent of `_fillRadialRows` — it walks
    // the ring list rather than one point list — so every channel that path
    // writes must be written here too.
    var index = 0;
    for (final donut in donuts) {
      final key = donut.name ?? '';
      for (final point in donut.points) {
        rows[index].strings[ring.slot] = key;
        rows[index].strings[category.slot] = point.label ?? '';
        rows[index].numbers[value.slot] = point.y;
        if (radius != null) {
          rows[index].numbers[radius.slot] = point.pointStyle?.size ?? 0;
        }
        if (sliceColor != null) {
          rows[index].colors[sliceColor.slot] = point.pointStyle?.color;
        }
        index += 1;
      }
    }
    // Single-ring collapse carries the center on the lone series (no-op =
    // hidden, `rings.single.copyWith(centerContent: mark.center ?? hidden)`);
    // the multi-ring composition carries it on the shared config (no-op = the
    // config's visible default, `mark.center == null ? const
    // ConcentricDonutConfig() : ...`). See `_lowerRadial`'s concentric branch.
    final captured = configuration.concentricDonutConfig!;
    final center = donuts.length == 1
        ? _markCenter(donuts.single.centerContent, DonutCenterContent.hidden)
        : _markCenter(captured.centerContent, const DonutCenterContent());
    // …and the two shapes therefore report an omitted formatter at DIFFERENT
    // document sites. The collapse's center is series[0]'s own; the multi-ring
    // composition's belongs to the plot-level config, where the config form
    // reports it too — and where, unlike any series path, it actually exists.
    final plannedCenter = center == null
        ? null
        : donuts.length == 1
        ? _PlannedCenter.onSeries(center, 0)
        : _PlannedCenter.onConcentricConfig(center);
    // What lowering REBUILDS from `center` alone — the shape every concentric
    // chart emitted before `concentric:` existed. When it already reproduces the
    // captured composition the mark keeps carrying just the center, so those
    // charts emit exactly the text they emitted before; only a composition the
    // center cannot express (a ring gap, order, weights, radii or legend mode)
    // carries the whole config — which is precisely the set that used to be
    // REFUSED. The center itself is carried verbatim by `_markCenter`, so a
    // styled or formatted center no longer forces the config onto the mark.
    final fromCenter = donuts.length == 1 || center == null
        ? const ConcentricDonutConfig()
        : ConcentricDonutConfig(centerContent: center);
    final carriesConfig = fromCenter != captured;
    // ONE mark splits into N ring series, so the label config is carried as a
    // base plus overrides: ring 0 fixes `dataLabels`, and only the rings whose
    // config DIFFERS from it are projected into `dataLabelsByRing`. A uniform
    // composition therefore builds an EMPTY map, which is kept as null below so
    // it emits exactly the text it emitted before this channel existed.
    //
    // An override that happens to EQUAL the family default is still projected:
    // "same as the default" and "same as the base" are different facts, and
    // only the second one means the ring needs no entry.
    final baseLabels = donuts.first.dataLabels;
    final labelsByRing = <String, PieDataLabelConfig>{
      for (final donut in donuts)
        if (donut.dataLabels != baseLabels)
          (donut.name ?? ''): donut.dataLabels,
    };
    return _RadialPlan(
      kind: _RadialKind.concentric,
      verb: 'geomDonut',
      rows: rows,
      category: category,
      value: value,
      radius: radius,
      ring: ring,
      sliceColor: sliceColor,
      // The config owns the center when it rides the mark: lowering reads
      // `concentric.centerContent` and REFUSES a mark that sets both, so the
      // plan's `center` (what `geomDonut` emits as `center:`) drops out too.
      center: carriesConfig ? null : plannedCenter,
      // A concentric ring donut lowers per ring with no per-mark name/color —
      // the ring key supplies each series' name — so those inherited fields are
      // deliberately left null here. The mark carries ONE unit / style /
      // selection / slice-config set applied to EVERY ring (that is how
      // `_lowerConcentricRings` lowers), so the first ring's config is used;
      // rings whose config differs are caught by the round-trip proof (each
      // lowered ring must match), never silently flattened. `dataLabels` is the
      // exception: it has a per-ring override channel, projected above.
      mark: DonutMark<_SourceRow>(
        id: markId,
        unit: donuts.first.unit,
        category: _string(category),
        value: _number(value),
        radius: radius == null ? null : _number(radius),
        ring: _string(ring),
        sliceColor: sliceColor == null ? null : _color(sliceColor),
        style: donuts.first.donutStyle,
        selectionStyle: donuts.first.selectionStyle,
        center: carriesConfig ? null : center,
        concentric: carriesConfig ? captured : null,
        // Null whenever the captured ids follow the pattern, which is what
        // keeps a conforming composition's emitted text unchanged.
        ringIds: explicitRingIds,
        dataLabels: baseLabels,
        dataLabelsByRing: labelsByRing.isEmpty ? null : labelsByRing,
        sliceRadiusConfig: donuts.first.sliceRadiusConfig,
        sliceGroupingConfig: donuts.first.sliceGroupingConfig,
      ),
    );
  }

  /// Plans a polar chart: one shared category field, one value field per
  /// series, and the captured plot-level configuration.
  ///
  /// The first series fixes the category domain and its order. Every polar
  /// series in a rendered chart shares that domain — `PolarColumnComposition
  /// .validate` enforces it at mount, at hydration AND now at grammar lowering,
  /// and `ChartGrammarSourceGenerator.generate` hydrates before this runs. So
  /// the misalignment guard below is UNREACHABLE through the public entry point
  /// and is deliberately kept as defence in depth for a future caller that
  /// builds a `HydratedChartConfiguration` directly: the rows are sized from the
  /// FIRST series' domain, so a longer or differently-labelled second series
  /// would index past the end of the row list (a `RangeError`) or re-lower with
  /// a synthesised zero, which is a different chart. Blocking by name beats
  /// both.
  _PolarChartPlan? _planPolarChart(
    List<PolarColumnChartSeries> series,
    void Function(String message, {String? path}) block,
  ) {
    final categories = <String>[
      for (final point in series.first.points) point.label ?? '',
    ];
    final misaligned = <String>[
      for (final item in series.skip(1))
        if (!_sameCategoryDomain(categories, item)) item.id,
    ];
    if (misaligned.isNotEmpty) {
      block(
        'Grammar chain not emitted: N geomPolar marks read ONE row list, so '
        'every polar series must have exactly one value at every category of '
        'the shared domain, in the same order. "${series.first.id}" sets the '
        'domain; these series do not match it: ${misaligned.join(', ')}.',
        path: r'$.series[*].data',
      );
      return null;
    }

    // EVERY field must be allocated before the rows are synthesised: a row is
    // sized from the slot counts at the moment it is built. The advanced
    // per-series channels are allocated INTERLEAVED with their series' value so
    // a series that carries none leaves the field order exactly as it was.
    final category = _addField('category', _FieldKind.string);
    final values = <_Field>[];
    final columnColors = <_Field?>[];
    final targets = <_Field?>[];
    final intervalLows = <_Field?>[];
    final intervalHighs = <_Field?>[];
    for (final item in series) {
      values.add(_addField('value', _FieldKind.number));
      // A per-point colour is `columnColors` reversed: `_fromMap` writes it as
      // `PointStyle.color(...)`, and lowering writes it back the same way, so a
      // point whose style carries anything ELSE is caught by the proof.
      columnColors.add(
        item.points.any((point) => point.pointStyle?.color != null)
            ? _addField('columnColor', _FieldKind.color)
            : null,
      );
      targets.add(
        item.targetValues.isEmpty
            ? null
            : _addField('target', _FieldKind.optionalNumber),
      );
      // The two bound lists are supplied together or not at all (the series
      // validates it), so one flag decides both fields.
      final hasIntervals = item.intervalLowerValues.isNotEmpty;
      intervalLows.add(
        hasIntervals
            ? _addField('intervalLow', _FieldKind.optionalNumber)
            : null,
      );
      intervalHighs.add(
        hasIntervals
            ? _addField('intervalHigh', _FieldKind.optionalNumber)
            : null,
      );
    }
    final rows = _synthesiseRadialRows(categories.length);
    for (var index = 0; index < categories.length; index++) {
      rows[index].strings[category.slot] = categories[index];
    }
    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final item = series[seriesIndex];
      final points = item.points;
      final value = values[seriesIndex];
      final columnColor = columnColors[seriesIndex];
      final target = targets[seriesIndex];
      final low = intervalLows[seriesIndex];
      final high = intervalHighs[seriesIndex];
      for (var index = 0; index < points.length; index++) {
        rows[index].numbers[value.slot] = points[index].y;
        if (columnColor != null) {
          rows[index].colors[columnColor.slot] =
              points[index].pointStyle?.color;
        }
        // These three lists are PARALLEL ARRAYS indexed by category — the same
        // alignment `PolarColumnChartSeries._fromMap` builds them with — so the
        // row at a category index carries that category's entry, null included.
        if (target != null) {
          rows[index].optionalNumbers[target.slot] = item.targetValues[index];
        }
        if (low != null && high != null) {
          rows[index].optionalNumbers[low.slot] =
              item.intervalLowerValues[index];
          rows[index].optionalNumbers[high.slot] =
              item.intervalUpperValues[index];
        }
      }
    }

    return _PolarChartPlan(
      rows: rows,
      category: category,
      series: <_PolarSeriesPlan>[
        for (var index = 0; index < series.length; index++)
          _PolarSeriesPlan(
            value: values[index],
            columnColor: columnColors[index],
            target: targets[index],
            intervalLow: intervalLows[index],
            intervalHigh: intervalHighs[index],
            mark: PolarMark<_SourceRow>(
              id: series[index].id,
              name: series[index].name,
              color: series[index].color,
              unit: series[index].unit,
              category: _string(category),
              value: _number(values[index]),
              // Carry the column unit, styling and selection so a styled polar
              // column round-trips (PolarMark.style →
              // PolarColumnChartSeries.polarStyle, .selectionStyle →
              // .selectionStyle, .unit → .unit), plus the advanced per-category
              // channels and their two styles and the preset — which is what
              // turned the references / intervals / rose presentations from an
              // honest refusal into an emitted chain.
              style: series[index].polarStyle,
              selectionStyle: series[index].selectionStyle,
              columnColor: columnColors[index] == null
                  ? null
                  : _color(columnColors[index]!),
              target: targets[index] == null
                  ? null
                  : _nullableNumber(targets[index]!),
              targetMarkerStyle: series[index].targetMarkerStyle,
              intervalLow: intervalLows[index] == null
                  ? null
                  : _nullableNumber(intervalLows[index]!),
              intervalHigh: intervalHighs[index] == null
                  ? null
                  : _nullableNumber(intervalHighs[index]!),
              intervalStyle: series[index].intervalStyle,
              preset: series[index].preset,
            ),
          ),
      ],
      // Always non-null here: hydration REFUSES a document that carries polar
      // series without a polar configuration (`_validatePolarComposition`), and
      // `generate` returns that failure before this planner runs. The fallback
      // is the same defence in depth as the domain guard above — a direct
      // caller must get the default config, not a null that the round-trip
      // proof would then report as a lost PolarChartConfig.
      config: configuration.polarChartConfig ?? const PolarChartConfig(),
    );
  }

  /// Whether [series] carries exactly [categories], in the same order.
  bool _sameCategoryDomain(
    List<String> categories,
    PolarColumnChartSeries series,
  ) {
    if (series.points.length != categories.length) return false;
    for (var index = 0; index < categories.length; index++) {
      if ((series.points[index].label ?? '') != categories[index]) return false;
    }
    return true;
  }

  /// A radius field when ANY point across [seriesList] carries a slice/column
  /// size (the second-metric variable radius), or null otherwise.
  _Field? _radialRadiusField(List<ChartSeries> seriesList) {
    final hasRadius = seriesList.any(
      (series) => series.points.any((point) => point.pointStyle?.size != null),
    );
    return hasRadius ? _addField('radius', _FieldKind.number) : null;
  }

  /// A slice-colour field when ANY point across [seriesList] carries a colour
  /// override, or null otherwise.
  ///
  /// Allocated on ANY point, not on every point: `PieChartSeries.fromMap` /
  /// `DonutChartSeries.fromMap` build `sliceColors` from the entries that HAVE
  /// a colour, so a partially-coloured chart reverses to a field whose
  /// uncoloured rows are null, which the lowering helper skips again.
  ///
  /// MUST be called before [_synthesiseRadialRows] — a row is sized from the
  /// slot counts at the moment it is built.
  _Field? _radialSliceColorField(List<ChartSeries> seriesList) {
    final hasColor = seriesList.any(
      (series) => series.points.any((point) => point.pointStyle?.color != null),
    );
    return hasColor ? _addField('sliceColor', _FieldKind.color) : null;
  }

  /// Fills one row per point with the reversed radial channels.
  void _fillRadialRows(
    List<_SourceRow> rows,
    List<ChartDataPoint> points,
    _Field category,
    _Field value,
    _Field? radius, {
    required _Field? ring,
    required _Field? sliceColor,
  }) {
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      rows[index].strings[category.slot] = point.label ?? '';
      rows[index].numbers[value.slot] = point.y;
      if (radius != null) {
        rows[index].numbers[radius.slot] = point.pointStyle?.size ?? 0;
      }
      // Null is written through deliberately: a category with no override is a
      // real state the lowering reproduces by leaving it out of `sliceColors`.
      if (sliceColor != null) {
        rows[index].colors[sliceColor.slot] = point.pointStyle?.color;
      }
    }
  }

  List<_SourceRow> _synthesiseRadialRows(int rowCount) => <_SourceRow>[
    for (var index = 0; index < rowCount; index++)
      _SourceRow(
        List<double>.filled(_numberSlots, 0),
        List<String>.filled(_stringSlots, ''),
        List<DateTime?>.filled(_stampSlots, null),
        List<double?>.filled(_optionalNumberSlots, null),
        List<Color?>.filled(_colorSlots, null),
      ),
  ];

  /// The mark id a concentric composition takes when its captured ring ids do
  /// NOT follow the `'<markId>-<ringKey>'` pattern.
  ///
  /// In that case `ringIds` names every ring explicitly — the map is all or
  /// nothing — so the mark id no longer contributes to any series id and only
  /// has to be stable and readable. A fixed word is both, and it cannot collide
  /// with anything: the chain carries exactly one radial mark.
  static const String _synthesisedConcentricMarkId = 'donut';

  /// The shared markId of a concentric composition, recovered from the
  /// `'<markId>-<ringKey>'` id pattern the forward lowering writes, or null when
  /// the ids do not match it.
  ///
  /// Null is not a refusal on its own any more: `_planConcentric` falls back to
  /// naming every ring explicitly through `DonutMark.ringIds`. It IS still the
  /// discriminator, though — the fallback runs only when this returns null, so
  /// a conforming composition keeps emitting exactly what it emitted before.
  String? _concentricMarkId(List<DonutChartSeries> donuts) {
    final first = donuts.first;
    final firstKey = first.name ?? '';
    if (firstKey.isEmpty) return null;
    final suffix = '-$firstKey';
    if (!first.id.endsWith(suffix) || first.id.length == suffix.length) {
      return null;
    }
    final candidate = first.id.substring(0, first.id.length - suffix.length);
    for (final donut in donuts) {
      final key = donut.name ?? '';
      if (key.isEmpty || donut.id != '$candidate-$key') return null;
    }
    return candidate;
  }

  /// The center to carry on the mark, or null when the captured center is the
  /// [noOp] value the lowering restores when a mark carries no center — so
  /// `geomDonut` emits no `center:` for it. The two donut shapes have DIFFERENT
  /// no-op centers: a plain/collapsed donut restores `DonutCenterContent.hidden`
  /// (`mark.center ?? hidden`), while a concentric composition restores the
  /// config's default `const DonutCenterContent()` (visible).
  ///
  /// The captured object is carried VERBATIM — `labelStyle`, `valueStyle` and
  /// `valueFormatter` included — exactly as `dataLabels` and the slice configs
  /// already are, so the round-trip proof compares like with like instead of
  /// refusing every styled or formatted center. A `valueFormatter` is a live
  /// callback with no literal form; it degrades to an honest placeholder at
  /// EMISSION (with a `runtimeValueOmitted` warning), not by being dropped here.
  DonutCenterContent? _markCenter(
    DonutCenterContent captured,
    DonutCenterContent noOp,
  ) => captured == noOp ? null : captured;

  /// The first part of a radial lowered plot that does not match the captured
  /// chart, or null when everything matches.
  ///
  /// Unlike [_firstMismatch], a radial `LoweredPlot` legitimately nulls the X
  /// axis, Y axes and grid (radial has no Cartesian coordinate space), so those
  /// are NOT compared. It DOES compare both radial chart-level configs — but the
  /// two comparisons have different strengths, and saying so is the honest
  /// framing:
  ///
  /// - `ConcentricDonutConfig` is either RECONSTRUCTED by lowering from the
  ///   donut mark's `center` (when the center alone expresses the captured
  ///   composition) or carried verbatim on `DonutMark.concentric` (when it does
  ///   not). The first case genuinely proves what the mark carries; the second
  ///   is the same passthrough tripwire as the polar config below.
  /// - `PolarChartConfig` rides `PlotSpec.polar` verbatim, so the re-lowered
  ///   plot hands the SAME object back. That comparison is a regression tripwire
  ///   on the lowering — before this slice lowering substituted
  ///   `const PolarChartConfig()` and the check fired for every customised
  ///   config — not a proof about the emitted `.polarConfig(...)` LITERAL. The
  ///   literal's fidelity rests on it being written by the config emitter's own
  ///   shared renderer (so the two forms cannot disagree), on
  ///   `test/meta/source_emitter_drift_test.dart`, and on the per-field
  ///   assertions in the emitter tests.
  ///
  /// The same distinction applies to every field the proof spec carries verbatim
  /// (theme, interaction, title, subtitle, legend): a passthrough comparison
  /// guards against lowering silently dropping it, which is worth having, and is
  /// not the same thing as proving the emitted text.
  ({String subject, String detail})? _firstRadialMismatch(LoweredPlot lowered) {
    if (lowered.series.length != configuration.series.length) {
      return (subject: 'the series list', detail: _genericLossDetail);
    }
    for (var index = 0; index < lowered.series.length; index++) {
      final expected = configuration.series[index];
      if (lowered.series[index] != expected) {
        return (
          subject: 'series "${expected.id}"',
          detail: _radialSeriesLossDetail(expected, lowered.series[index]),
        );
      }
    }
    if (configuration.annotations.isNotEmpty) {
      return (
        subject: 'the annotation list',
        detail:
            'A radial chain carries no annotations, so a captured annotation '
            'cannot be reproduced.',
      );
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
    if (lowered.title != configuration.title) {
      return (subject: 'the title', detail: _genericLossDetail);
    }
    if (lowered.subtitle != configuration.subtitle) {
      return (subject: 'the subtitle', detail: _genericLossDetail);
    }
    if (lowered.showLegend != configuration.showLegend) {
      return (subject: 'the legend visibility', detail: _genericLossDetail);
    }
    if (lowered.concentricDonutConfig != configuration.concentricDonutConfig) {
      return (
        subject: 'the concentric-donut composition',
        detail:
            'A concentric chain sets the ring gap, order, weights, radii, legend '
            'mode and shared center with geomDonut(concentric: ...), so the '
            're-lowered plot must carry the captured ConcentricDonutConfig '
            'exactly. This one does not — the captured chart pairs the config '
            'with a radial family that composes no rings.',
      );
    }
    // The lowering tripwire described above: it fires only if lowering stops
    // carrying `PlotSpec.polar` through to `LoweredPlot.polarChartConfig`, which
    // is precisely what it did before `.polarConfig(...)` existed.
    if (lowered.polarChartConfig != configuration.polarChartConfig) {
      return (
        subject: 'the polar chart configuration',
        detail:
            'A polar chain sets the plot-level pane, angular/radial axis, '
            'composition and thresholds with .polarConfig(...), so the '
            're-lowered plot must carry the captured PolarChartConfig exactly. '
            'This one does not.',
      );
    }
    return null;
  }

  /// Explains why a captured radial series is not reproduced by the lowered one.
  ///
  /// Two causes are DIAGNOSED by name before the catch-all sentence runs,
  /// because the catch-all describes neither of them and a reader who trusts it
  /// goes hunting for something that is not there:
  ///
  ///  1. a donut center the reversal cannot carry ([_radialCenterLossDetail]);
  ///  2. a point whose `PointStyle` sets no override at all
  ///     ([_radialBareStyleLossDetail]) — which the catch-all would call a
  ///     style "beyond" a colour and size override when it falls short of both.
  ///
  /// What the catch-all then covers is series metadata, a per-point style
  /// beyond what the family reverses, and a polar interval list whose every
  /// entry is null (which reverses to "no intervals" rather than to a list of
  /// nulls). Its round-trip list is accurate at that point and only there: a
  /// series that reaches it has a matching center, so naming the center among
  /// the things that round-tripped is true of the series being described.
  ///
  /// The per-point sentence is FAMILY-AWARE because the two radial families
  /// reverse different amounts of a `PointStyle`. Pie and donut reverse both
  /// `color` (as `sliceColor:`) and `size` (as `radius:`), because their
  /// `fromMap` builds the general `PointStyle(color:, size:)`. Polar reverses
  /// `color` only — `PolarColumnChartSeries._fromMap` writes the narrowing
  /// `PointStyle.color(...)` and a polar column ignores `size` when it paints.
  /// Telling a pie author that `size` is un-carried would be false.
  String _radialSeriesLossDetail(ChartSeries expected, ChartSeries lowered) {
    final center = _radialCenterLossDetail(expected, lowered);
    if (center != null) return center;
    final bareStyle = _radialBareStyleLossDetail(expected);
    if (bareStyle != null) return bareStyle;
    final perPoint = expected is PolarColumnChartSeries
        ? 'a per-point style beyond a colour override'
        : 'a per-point style beyond a colour and size override';
    return 'It carries a series option the radial marks do not carry — the '
        'category, value, optional radius, concentric ring, donut center, '
        'unit, series style, selection style, data labels, (pie/donut) the '
        'per-slice colours and the slice-radius and grouping configs and '
        '(polar) the preset, per-category column colours, targets and '
        'intervals round-trip, but series metadata, $perPoint, and an all-null '
        'polar interval list do not.';
  }

  /// Names the DONUT CENTER as the cause when it is, or null when the captured
  /// and rebuilt centers match.
  ///
  /// [_markCenter] now carries the captured center VERBATIM, so a center's own
  /// fields — styles and formatter included — no longer diverge on their own.
  /// The one remaining way a center differs is that it is replaced wholesale,
  /// which is what a concentric composition does to a ring that carries a
  /// center of its own: the mark holds ONE shared center and every ring
  /// re-lowers hidden.
  String? _radialCenterLossDetail(ChartSeries expected, ChartSeries lowered) {
    if (expected is! DonutChartSeries || lowered is! DonutChartSeries) {
      return null;
    }
    if (expected.centerContent == lowered.centerContent) return null;
    return 'Its donut center is not the one the chain would rebuild. A '
        'concentric composition carries ONE shared donut center on '
        'geomDonut(concentric: ...) and re-lowers every ring with a hidden '
        'center, so a ring carrying a center of its own cannot be reproduced.';
  }

  /// Names an OVERRIDE-LESS `PointStyle` as the cause when the series carries
  /// one, or null when every point style either sets an override or is absent.
  ///
  /// The reversal builds a point style out of the row channels it allocated, so
  /// a style with nothing to allocate reverses to `pointStyle: null`. The
  /// document codec disagrees — it writes the style as `{}` and decodes it back
  /// to a non-null `const PointStyle()` — and `PointStyle.==` separates the
  /// two. The asymmetry is real, so it stays an honest refusal; it just is not
  /// the refusal the catch-all sentence describes.
  String? _radialBareStyleLossDetail(ChartSeries expected) {
    final hasBareStyle = expected.points.any(
      (point) => point.pointStyle != null && !point.pointStyle!.hasOverrides,
    );
    if (!hasBareStyle) return null;
    return 'It carries a point whose PointStyle sets NO override at all. The '
        'reversal builds a point style out of the row channels it allocated, '
        'so an override-less style reverses to no style — which is not what '
        'the captured document holds. The asymmetry is real, so it is refused '
        'rather than emitted as a chain that quietly rewrites the document.';
  }

  // =========================================================================
  // Gates
  // =========================================================================

  /// Whether a grammar geometry exists that reverses [series]. Widens the old
  /// Cartesian-only gate to the radial families the grammar now lowers (pie,
  /// donut, polar-column). Radial-bar, gauge and range-area stay refused — they
  /// have no `geom*` verb and no `Mark` subtype.
  bool _isEmittableFamily(ChartSeries series) => switch (series) {
    CandlestickChartSeries() => true,
    LineChartSeries() => true,
    ScatterChartSeries() => true,
    AreaChartSeries() => true,
    BarChartSeries() => true,
    PieChartSeries() => true,
    DonutChartSeries() => true,
    PolarColumnChartSeries() => true,
    _ => false,
  };

  /// Whether [series] lowers through the RADIAL branch of `spec.lower()` and so
  /// must be reversed by the dedicated radial path rather than the Cartesian
  /// per-series shared-x reversal.
  bool _isRadialFamily(ChartSeries series) =>
      series is PieChartSeries ||
      series is DonutChartSeries ||
      series is PolarColumnChartSeries;

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
    // concentricDonutConfig and polarChartConfig are NO LONGER listed here: the
    // grammar carries both (`geomDonut(concentric:)` and `.polarConfig(...)`),
    // and the round-trip proof (_firstRadialMismatch) refuses anything they do
    // not reproduce with a named reason. Only radialBarChartConfig stays gated —
    // radial-bar has no grammar mark.
    if (configuration.radialBarChartConfig != null) {
      lost.add('radialBarChartConfig');
    }
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
  ///
  /// The comparisons below have two DIFFERENT strengths, and — exactly as for
  /// [_firstRadialMismatch] — saying which is which is the honest framing:
  ///
  /// - **Genuine re-lowering.** `series` and `annotations` are REBUILT by
  ///   `spec.lower()` out of the reconstructed marks: each point is recomputed
  ///   by running the emitter's own accessors over the synthesised rows, and
  ///   each reference mark is turned back into a `ChartAnnotation`. Comparing
  ///   those to the captured ones field-for-field (`operator ==` for series,
  ///   [_sameAnnotation] for annotations, which spells the comparison out
  ///   because `ChartAnnotation` declares no `operator ==`) genuinely proves
  ///   the reconstruction: a channel, value or option a mark fails to carry
  ///   diverges here and is refused. Two caveats sit inside that proof. First,
  ///   a config object a mark carries VERBATIM (a data-label or style config)
  ///   travels into the rebuilt series as the captured instance, so that field
  ///   is a passthrough sitting inside an otherwise genuine comparison. Second,
  ///   the series comparison holds ONE normalisation — the legacy single-axis
  ///   binding — which the comparison site below states, gates and explains;
  ///   nothing else about a series is normalised away.
  /// - **Passthrough.** `xAxis`, `theme`, `interaction`, `grid`, `title`,
  ///   `subtitle` and `showLegend` are handed to the proof spec AS the captured
  ///   instances (see the spec built in `_tryEmitChain`) and `lowerPlotSpec`
  ///   assigns them straight onto the `LoweredPlot`, so each of those
  ///   comparisons is an instance against ITSELF. They are regression TRIPWIRES
  ///   on lowering — they fire if lowering ever stops forwarding a field or
  ///   substitutes a default — and prove nothing about the emitted
  ///   `.xAxis(...)` / `.theme(...)` / `.grid(...)` / `.title(...)` /
  ///   `.legend(...)` TEXT, which the proof never reads. (Verified by mutation:
  ///   deleting the `.grid(...)` and `.title(...)` emission produces ZERO
  ///   refusals here — only the emitter test that asserts the emitted text
  ///   fails.) `yAxes` sits just off pure passthrough: `_resolveAxes` returns
  ///   the declared instances unchanged and normalises only a blank `id` and an
  ///   empty list (replaced by one synthesised left axis), so this comparison
  ///   catches exactly those two normalisations and is instance-vs-itself
  ///   otherwise.
  ///
  /// The emitted literals rest on the guards named in the library docstring
  /// instead: the config emitter's shared renderers behind public seams,
  /// `test/meta/source_emitter_drift_test.dart`, and per-field assertions on
  /// the emitted text in the emitter tests — plus, on this Cartesian path,
  /// `test/unit/source/chart_grammar_source_generator_test.dart`'s third
  /// assertion, which hand-writes the equivalent chain and requires the
  /// document it extracts to equal the captured one.
  ({String subject, String detail})? _firstMismatch(LoweredPlot lowered) {
    if (lowered.series.length != configuration.series.length) {
      return (subject: 'the series list', detail: _genericLossDetail);
    }
    // A chart authored through the single-axis path carries no per-series
    // binding at all, while lowering ALWAYS binds — `_bindAxis` resolves
    // `mark.yAxisId ?? axes.first.id` and stamps the resolved axis onto every
    // series. `BravenPlot` now mounts that same legacy shape for a chain that
    // declares one axis and binds no mark (see `braven_plot.dart`), so the two
    // are the SAME chart and the binding lowering added is not a difference.
    //
    // The gate is deliberately narrow, and the narrowness is the whole point.
    // "A null yAxisId means axes.first" is WRONG: `getEffectiveYAxes` ignores
    // the widget-level yAxis as soon as any series carries an inline config,
    // and `getEffectiveBindings` sends an unbound series to a synthetic
    // 'primary_axis' rather than to the first declared axis. A document with
    // one series bound inline and one unbound is reachable, and treating the
    // unbound one as bound to the other's axis renders a DIFFERENT chart
    // (measured: 4265 of 960000 pixels differ under
    // normalizationMode.perSeries). Hence: every captured series unbound, and
    // exactly one declared axis.
    //
    // The two clauses are NOT equally load-bearing and are NOT equally
    // guarded, and saying which is which is the honest framing. Each of these
    // was measured by mutation, applied and reverted inside one invocation:
    //
    //  - Dropping the all-unbound clause FAILS four tests — round-trip shapes
    //    5, 29b, 29c and 29d, plus the named guard below. The clause is
    //    load-bearing in the opposite direction from the obvious one: it is
    //    what keeps a single-axis chart whose captured series ARE bound
    //    EMITTING. Without it the lowered side is stripped while the captured
    //    side keeps its binding, so the comparison can never be met and a
    //    perfectly reproducible chart is wrongly REFUSED. "a single-axis chart
    //    with an EXPLICIT binding still emits" states that coupling by name.
    //  - Dropping the `axes.length == 1` clause on its own changes nothing any
    //    test can see: a document declaring two axes with no series bound is
    //    rejected a layer earlier, by the grammar's own unboundAxis
    //    diagnostic, because lowering binds every unbound mark to `axes.first`
    //    and leaves the second axis with nothing measuring against it. That
    //    half really is defence in depth, and no test attributes a refusal to
    //    it. Dropping BOTH clauses together DOES fail (shape 3, multi-axis),
    //    so the pair is guarded even though this half alone is not.
    //  - Normalising BOTH sides instead — the "null means axes.first" shape —
    //    makes the mixed-binding document emit and fails "a MIXED binding is
    //    still refused". That guard pins the ASYMMETRY of the comparison
    //    below, NOT this gate: it stays green under every widening of the gate,
    //    up to and including deleting it outright, because the captured side is
    //    never stripped and its binding always has to be met.
    final legacySingleAxis =
        configuration.axes.length == 1 &&
        configuration.series.every(
          (series) => series.yAxisId == null && series.yAxisConfig == null,
        );
    for (var index = 0; index < lowered.series.length; index++) {
      final expected = configuration.series[index];
      // Only the LOWERED side is normalised. The captured side is left exactly
      // as it was extracted, so a captured binding can never be normalised
      // AWAY — the comparison still has to meet it, whatever the gate says.
      final actual = legacySingleAxis
          ? _withoutAxisBinding(lowered.series[index])
          : lowered.series[index];
      if (actual != expected) {
        // The NORMALISED series, deliberately: the detail has to explain the
        // comparison that actually failed. Handing the un-normalised one over
        // makes the axis sentence reachable for a chart whose binding this
        // loop already normalised away — a legacy single-axis chart refused
        // for a per-point field would then be told to "bind every series
        // explicitly — or none", which it already satisfies. When the gate did
        // NOT apply, or the family cannot be unbound, `actual` IS the lowered
        // series and the axis sentence stays exactly as reachable as before.
        return (
          subject: 'series "${expected.id}"',
          detail: _seriesLossDetail(expected, actual),
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
    // Near-passthrough (see the doc above): `_resolveAxes` returns the declared
    // axis instances, so this catches the two normalisations it performs — an
    // empty captured axis list, and an axis whose `id` lowering has to fill in.
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
    // The X axis, theme and interaction ride the proof spec verbatim and
    // lowering hands the same instances back, so these three are the
    // passthrough tripwires described above: they fire if lowering ever stops
    // forwarding one of them, and say nothing about the emitted `.xAxis(...)` /
    // `.theme(...)` text — that is the shared config emitter's, the drift
    // gate's and the emitted-text assertions' job.
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
    // Grid, title, subtitle and legend visibility ride the proof spec verbatim
    // too, so — exactly like the X axis, theme and interaction above — these
    // are the same instance-vs-itself tripwires on lowering, not proofs about
    // the emitted `.grid(...)` / `.title(...)` / `.legend(...)` literals.
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
  /// difference is the axis binding, that is called out specifically — and
  /// only the MIXED case can reach it, because [_firstMismatch] passes the
  /// series it actually compared: for a legacy single-axis chart the binding
  /// has already been normalised off the [lowered] side, so it cannot differ
  /// here and the sentence cannot fire. (Stated as a contract, not as an
  /// argument about argument order: an all-unbound chart refused for a
  /// per-point field used to be told to bind every series "explicitly — or
  /// none", advice it already satisfied.)
  String _seriesLossDetail(ChartSeries expected, ChartSeries lowered) {
    final field = _firstUncarriedField(expected, lowered);
    if (field != null) {
      return 'It carries $field, which no V1 ${_familyWord(expected)} mark '
          'carries.';
    }
    // Per-POINT options are named before the axis binding below. For a MIXED
    // binding — the one shape that still reaches the axis sentence — both are
    // true at once, and the per-point field is the more specific of the two.
    final pointDetail = _pointLossDetail(expected, lowered);
    if (pointDetail != null) return pointDetail;
    if (expected.yAxisId != lowered.yAxisId ||
        (expected.yAxisConfig == null) != (lowered.yAxisConfig == null)) {
      return 'The captured chart leaves this series\' yAxisId unset while the '
          'grammar binds every series to an explicit axis, so the '
          'reconstructed chain would render a different chart document. A '
          'chart that leaves EVERY series unbound is reproduced as the '
          'single-axis chart it is; this one does not, so bind every series '
          'explicitly — or none — to express it as a chain.';
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

  /// [series] with its Y-axis binding removed, for the legacy single-axis
  /// comparison in [_firstMismatch].
  ///
  /// The family list is [seriesWithoutAxisBinding]'s, shared with `BravenPlot`
  /// so the mount and this comparison can never disagree about which families
  /// can be unbound — see that function's docstring for what drift would cost.
  /// The fallback is this side's, and it is the OPPOSITE one: a family the
  /// helper cannot unbind is returned UNCHANGED, so it keeps its binding and
  /// FAILS the comparison rather than slipping through it.
  static ChartSeries _withoutAxisBinding(ChartSeries series) =>
      seriesWithoutAxisBinding(series) ?? series;

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

  /// The sentence naming the PER-POINT option set on [expected] that the
  /// [lowered] points do not reproduce, or null when the points differ in some
  /// other way — or not at all.
  ///
  /// Only `segmentStyle` is named, and it is named because it is deliberately
  /// NOT carried:
  ///
  ///  - measured, carrying it unblocks ZERO states — the one censused chart
  ///    using it still refuses on a marker field behind it;
  ///  - it would need a new row-field kind, since a synthesised row has slots
  ///    for numbers, strings, stamps and colours only; and
  ///  - it collides with `LineMark.colorBy`, which already bakes
  ///    `segmentStyle.color` into each point at lowering, so the same slot has
  ///    two owners.
  ///
  /// Dropping it silently would change the dashes and colours the chart draws,
  /// so the honest outcome is a NAMED boundary rather than the generic tail.
  /// Revisit with roadmap item 1d.
  ///
  /// That last collision is why there are TWO sentences rather than one. A
  /// style setting `strokeWidth` or `dashPattern` is one no V1 mark can produce
  /// at all. A COLOUR-ONLY style is the exact shape `_xyColorPoints` bakes for
  /// a line or area mark carrying `colorBy` + `colorEncoding` — the showcase
  /// ships such charts — so "no V1 line mark carries it" would be false there:
  /// the chain paints those colours, and it is the REVERSE direction that
  /// fails, since the channel and its encoding cannot be recovered from the
  /// baked result. Bar and scatter are deliberately not in that branch: a bar's
  /// colour channel bakes into `pointStyle` and a scatter's into `colorValue`,
  /// so a `segmentStyle` on either really is uncarried.
  static String? _pointLossDetail(ChartSeries expected, ChartSeries lowered) {
    // A length difference is not a per-point OPTION loss — it is a different
    // dataset — so it is left to the generic tail rather than misnamed here.
    if (expected.points.length != lowered.points.length) return null;
    var differs = false;
    var everyDifferenceIsColourOnly = true;
    for (var index = 0; index < expected.points.length; index++) {
      final captured = expected.points[index].segmentStyle;
      if (captured == lowered.points[index].segmentStyle) continue;
      differs = true;
      if (captured == null ||
          captured.color == null ||
          captured.strokeWidth != null ||
          captured.dashPattern != null) {
        everyDifferenceIsColourOnly = false;
      }
    }
    if (!differs) return null;
    final bakesSegmentColour =
        expected is LineChartSeries || expected is AreaChartSeries;
    if (everyDifferenceIsColourOnly && bakesSegmentColour) {
      return 'It carries a per-point segment colour. A chain paints those from '
          'a colorBy channel plus a colorEncoding, and the reverser cannot '
          'recover that channel from the baked colours, so declare colorBy and '
          'colorEncoding on the geom verb to express it.';
    }
    return 'It carries a per-point segment style, which no V1 '
        '${_familyWord(expected)} mark carries.';
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
      _FieldKind.optionalNumber => _optionalNumberSlots++,
      _FieldKind.color => _colorSlots++,
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

  /// [_string]'s `String`-typed sibling, for the per-point text accessors.
  ///
  /// The radial category channel is `FieldAccessor<T, Object?>` and takes
  /// [_string]; `label`/`pointKey` are `FieldAccessor<T, String?>`, and a
  /// closure typed `Object Function(_SourceRow)` is not assignable to that.
  String Function(_SourceRow) _text(_Field field) =>
      (row) => row.strings[field.slot];

  /// Plans one per-point text accessor (`label` or `pointKey`) for [series],
  /// or returns null when no point carries one.
  ///
  /// The row slot is a NON-NULLABLE `String`, so a point that carried nothing
  /// is written as `''`. That is not a lossy shortcut: lowering reads `''` back
  /// as "no value" (see `_pointText` in `plot_lowering.dart`), so a partially
  /// labelled or partially keyed series reproduces exactly. It also matters for
  /// `pointKey` specifically — `ChartDataPoint` ASSERTS a non-empty key, so
  /// there is no other string a bare point could travel as.
  FieldAccessor<_SourceRow, String?>? _planPointText(
    ChartSeries series,
    String base,
    String role,
    Map<String, _Field> accessors,
    String? Function(ChartDataPoint) read,
  ) {
    if (series.points.every((point) => read(point) == null)) return null;
    final field = _addField(_suffixed(base, role), _FieldKind.string);
    accessors[role] = field;
    return _text(field);
  }

  DateTime Function(_SourceRow) _stamp(_Field field) =>
      (row) => row.stamps[field.slot]!;

  num? Function(_SourceRow) _nullableNumber(_Field field) =>
      (row) => row.optionalNumbers[field.slot];

  Color? Function(_SourceRow) _color(_Field field) =>
      (row) => row.colors[field.slot];

  _GeometryPlan _planGeometry(ChartSeries series, _Field xField) {
    final base = _identifier(_baseNameFor(series));
    final accessors = <String, _Field>{'x': xField};
    final x = _number(xField);
    final id = series.id;
    final name = series.name;
    final color = series.color;
    // `unit` is a SeriesMark field every Cartesian family carries, so it is
    // reversed once here beside the other shared identity fields.
    final unit = series.unit;
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
            unit: unit,
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
        final label = _planPointText(
          series,
          base,
          'label',
          accessors,
          (point) => point.label,
        );
        final pointKey = _planPointText(
          series,
          base,
          'pointKey',
          accessors,
          (point) => point.pointKey,
        );
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: LineMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            unit: unit,
            label: label,
            pointKey: pointKey,
            isXOrdered: series.isXOrdered,
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
        final label = _planPointText(
          series,
          base,
          'label',
          accessors,
          (point) => point.label,
        );
        final pointKey = _planPointText(
          series,
          base,
          'pointKey',
          accessors,
          (point) => point.pointKey,
        );
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
            unit: unit,
            label: label,
            pointKey: pointKey,
            isXOrdered: series.isXOrdered,
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
        final label = _planPointText(
          series,
          base,
          'label',
          accessors,
          (point) => point.label,
        );
        final pointKey = _planPointText(
          series,
          base,
          'pointKey',
          accessors,
          (point) => point.pointKey,
        );
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: AreaMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            unit: unit,
            label: label,
            pointKey: pointKey,
            isXOrdered: series.isXOrdered,
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
        final label = _planPointText(
          series,
          base,
          'label',
          accessors,
          (point) => point.label,
        );
        final pointKey = _planPointText(
          series,
          base,
          'pointKey',
          accessors,
          (point) => point.pointKey,
        );
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: BarMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            unit: unit,
            label: label,
            pointKey: pointKey,
            isXOrdered: series.isXOrdered,
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
      rows.add(
        _SourceRow(
          numbers,
          strings,
          stamps,
          List<double?>.filled(_optionalNumberSlots, null),
          List<Color?>.filled(_colorSlots, null),
        ),
      );
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
        // Per-point text is family-independent, so it is written once here
        // rather than in each arm. Only the four Cartesian geometry families
        // plan these fields, so a candlestick plan simply has neither key and
        // this reads nothing.
        //
        // A point that carried nothing is written as '' — the empty string is
        // how "no label / no key" travels through a non-nullable row slot, and
        // lowering reads it back as null.
        final labelField = plan.accessors['label'];
        final keyField = plan.accessors['pointKey'];
        if (labelField != null || keyField != null) {
          final point = series.points[index];
          if (labelField != null) {
            row.strings[labelField.slot] = point.label ?? '';
          }
          if (keyField != null) {
            row.strings[keyField.slot] = point.pointKey ?? '';
          }
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

  /// Emits the row class, row list and the RADIAL chain (one `geom*` verb, no
  /// `.x()` / `.yAxis()` / `.grid()` / `.transposed()` — radial lowering rejects
  /// those).
  String _emitRadialBody(_RadialPlan plan) {
    final writer = DartSourceWriter();
    _emitRowClass(writer);
    writer.writeLine();
    _emitRows(writer, plan.rows);
    writer.writeLine();
    writer.writeLine(
      'final ${options.variableName} = BravenChart.of('
      '${options.rowsVariableName})',
    );
    writer.indented(() {
      writer.indented(() {
        _emitRadialGeometry(writer, plan);
        _emitTheme(writer);
        _emitInteraction(writer);
        _emitTitle(writer);
        _emitLegend(writer);
        writer.writeLine('.build();');
      });
    });
    return writer.toString();
  }

  /// Emits the row class, row list and the POLAR chain: one `geomPolar` per
  /// series over the shared rows, then `.polarConfig(...)` when the plot-level
  /// configuration is not the default one lowering restores.
  String _emitPolarChartBody(_PolarChartPlan plan) {
    final writer = DartSourceWriter();
    _emitRowClass(writer);
    writer.writeLine();
    _emitRows(writer, plan.rows);
    writer.writeLine();
    writer.writeLine(
      'final ${options.variableName} = BravenChart.of('
      '${options.rowsVariableName})',
    );
    writer.indented(() {
      writer.indented(() {
        for (final item in plan.series) {
          _emitPolarGeometry(writer, plan.category, item);
        }
        if (plan.config != const PolarChartConfig()) {
          writer.writeLine('.polarConfig(');
          writer.indented(() {
            // The SHARED config-emitter rendering, so the chain's config
            // literal cannot disagree with the config form's.
            _config.emitPolarChartConfig(writer, null, plan.config);
            _absorbConfigWarnings();
          });
          writer.writeLine(')');
        }
        _emitTheme(writer);
        _emitInteraction(writer);
        _emitTitle(writer);
        _emitLegend(writer);
        writer.writeLine('.build();');
      });
    });
    return writer.toString();
  }

  /// Emits one `.geomPolar(...)` — the polar arm of [_emitRadialGeometry], over
  /// the plan's shared category field and this series' own value field.
  void _emitPolarGeometry(
    DartSourceWriter writer,
    _Field category,
    _PolarSeriesPlan plan,
  ) {
    final mark = plan.mark;
    writer.writeLine('.geomPolar(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(mark.id!));
      writer.namedArgument('category', category.accessor());
      writer.namedArgument('value', plan.value.accessor());
      _optionalString(writer, 'name', mark.name);
      _optionalColor(writer, 'color', mark.color);
      _optionalString(writer, 'unit', mark.unit);
      if (mark.style != null) {
        _config.emitPolarColumnStyle(writer, 'style', mark.style!);
      }
      if (mark.selectionStyle != null) {
        _config.emitRadialSelectionStyle(writer, mark.selectionStyle!);
      }
      // The advanced per-category channels, in the `geomPolar` signature's own
      // order. Each accessor field exists only when the captured series carried
      // that channel, and each style literal is written by the SHARED config
      // emitter (the same rendering the config form's `targetMarkerStyle:` /
      // `intervalStyle:` uses), which writes nothing for a default style.
      if (mark.preset == PolarColumnPreset.rose) {
        writer.namedArgument('rose', 'true');
      }
      if (plan.columnColor != null) {
        writer.namedArgument('columnColor', plan.columnColor!.accessor());
      }
      if (plan.target != null) {
        writer.namedArgument('target', plan.target!.accessor());
      }
      if (mark.targetMarkerStyle != null) {
        _config.emitPolarTargetMarkerStyle(
          writer,
          'targetMarkerStyle',
          mark.targetMarkerStyle!,
        );
      }
      if (plan.intervalLow != null && plan.intervalHigh != null) {
        writer.namedArgument('intervalLow', plan.intervalLow!.accessor());
        writer.namedArgument('intervalHigh', plan.intervalHigh!.accessor());
      }
      if (mark.intervalStyle != null) {
        _config.emitPolarIntervalStyle(
          writer,
          'intervalStyle',
          mark.intervalStyle!,
        );
      }
      _absorbConfigWarnings();
    });
    writer.writeLine(')');
  }

  void _emitRadialGeometry(DartSourceWriter writer, _RadialPlan plan) {
    final mark = plan.mark;
    writer.writeLine('.${plan.verb}(');
    writer.indented(() {
      writer.namedArgument('id', DartSourceWriter.stringLiteral(mark.id!));
      writer.namedArgument('category', plan.category.accessor());
      writer.namedArgument('value', plan.value.accessor());
      if (plan.radius != null) {
        writer.namedArgument('radius', plan.radius!.accessor());
      }
      if (plan.ring != null) {
        writer.namedArgument('ring', plan.ring!.accessor());
      }
      // `sliceColor:` sits after `radius:` / `ring:` in the geomPie/geomDonut
      // signatures, so it is written here to keep the emitted argument order
      // the same as the API's.
      if (plan.sliceColor != null) {
        writer.namedArgument('sliceColor', plan.sliceColor!.accessor());
      }
      _optionalString(writer, 'name', mark.name);
      _optionalColor(writer, 'color', mark.color);
      // `unit` is a shared RadialMark field carried by every family; the config
      // form writes the same `unit:` string on the series.
      _optionalString(writer, 'unit', mark.unit);
      // Style / selection / center / data labels / slice configs, in the geom
      // verbs' signature order. Every nested-config literal is written by the
      // SHARED config emitter (the same rendering the config form uses for
      // `pieStyle:` / `donutStyle:` / `polarStyle:` / `selectionStyle:` /
      // `dataLabels:` / `sliceRadiusConfig:` / `sliceGroupingConfig:`), so the
      // two forms cannot disagree; each seam writes nothing for a
      // family-default value, keeping a default-styled radial chain
      // byte-identical. A slice-radius `formatter` is a live callback: the seam
      // emits an honest placeholder comment and records the omission warning.
      switch (mark) {
        case PieMark<_SourceRow>():
          if (mark.style != null) {
            _config.emitRadialStyle(
              writer,
              'style',
              'PieChartStyle',
              mark.style!,
            );
          }
          if (mark.selectionStyle != null) {
            _config.emitRadialSelectionStyle(writer, mark.selectionStyle!);
          }
          if (mark.dataLabels != null) {
            _config.emitRadialLabels(writer, mark.dataLabels!, 0);
          }
          if (mark.sliceRadiusConfig != null) {
            _config.emitSliceRadiusConfig(writer, mark.sliceRadiusConfig!, 0);
          }
          if (mark.sliceGroupingConfig != null) {
            _config.emitSliceGroupingConfig(writer, mark.sliceGroupingConfig!);
          }
        case DonutMark<_SourceRow>():
          if (mark.style != null) {
            _config.emitRadialStyle(
              writer,
              'style',
              'DonutChartStyle',
              mark.style!,
              innerRadiusFactor: mark.style!.innerRadiusFactor,
              sweepAngleDegrees: mark.style!.sweepAngleDegrees,
            );
          }
          if (mark.selectionStyle != null) {
            _config.emitRadialSelectionStyle(writer, mark.selectionStyle!);
          }
          // Written by the config emitter's OWN centre renderer — the one the
          // config form's `centerContent:` and the concentric config both use —
          // so `center:` carries the styles and the formatter placeholder
          // instead of a four-field rebuild the proof would have to refuse.
          // The planner also decided WHERE the centre came from, so an omitted
          // formatter is reported at the site that actually holds it.
          if (plan.center case final planned?) {
            _config.emitDonutCenterContent(
              writer,
              'center',
              planned.content,
              warningMessage: planned.message,
              warningPath: planned.path,
            );
          }
          // `concentric:` and `center:` are mutually exclusive by lowering's
          // precedence rule, and the planner only carries a config the center
          // could not express — so a concentric chart whose composition IS the
          // default still emits neither, exactly as before.
          if (mark.concentric case final concentric?
              when concentric != const ConcentricDonutConfig()) {
            _config.emitConcentricDonutConfig(writer, 'concentric', concentric);
          }
          // Present only for a composition whose captured ids do not follow the
          // `'<markId>-<ringKey>'` pattern, so a conforming chart writes nothing
          // here and its emitted text is unchanged.
          if (mark.ringIds case final ringIds?) {
            _emitRingIds(writer, ringIds);
          }
          if (mark.dataLabels != null) {
            _config.emitRadialLabels(writer, mark.dataLabels!, 0);
          }
          // The per-ring overrides ride straight after their base, in the
          // `geomDonut` signature's order. The planner only builds this map for
          // rings that DIFFER from the base and keeps an empty one as null, so
          // a uniform-label composition reaches here with nothing to write and
          // emits exactly the text it emitted before. The seam itself is
          // UNCONDITIONAL: an entry equal to the family default is a real
          // override against a non-default base.
          if (mark.dataLabelsByRing case final byRing?) {
            _config.emitRadialLabelsByRing(writer, byRing);
          }
          if (mark.sliceRadiusConfig != null) {
            _config.emitSliceRadiusConfig(writer, mark.sliceRadiusConfig!, 0);
          }
          if (mark.sliceGroupingConfig != null) {
            _config.emitSliceGroupingConfig(writer, mark.sliceGroupingConfig!);
          }
        case PolarMark<_SourceRow>():
          // Kept for the sealed switch's exhaustiveness only: a polar chart is
          // planned by `_planPolarChart` and emitted by `_emitPolarGeometry`,
          // which writes exactly these two arguments.
          if (mark.style != null) {
            _config.emitPolarColumnStyle(writer, 'style', mark.style!);
          }
          if (mark.selectionStyle != null) {
            _config.emitRadialSelectionStyle(writer, mark.selectionStyle!);
          }
      }
      _absorbConfigWarnings();
    });
    writer.writeLine(')');
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
    // `null` is the WHOLE point of these two kinds: it is how a category with
    // no target, no interval and no colour override is written.
    _FieldKind.optionalNumber => switch (row.optionalNumbers[field.slot]) {
      final value? => DartSourceWriter.numberLiteral(value),
      _ => 'null',
    },
    _FieldKind.color => switch (row.colors[field.slot]) {
      final value? => DartSourceWriter.colorLiteral(value),
      _ => 'null',
    },
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
      RadialMark<_SourceRow>() => throw StateError(
        'unreachable: a radial mark reached _emitGeometry; radial charts are '
        'emitted through the dedicated radial chain (_emitRadialGeometry), never '
        'the Cartesian geometry switch',
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
      // `unit` sits on the shared SeriesMark intermediate, and every Cartesian
      // geom verb takes it in this slot — directly after `color:` — so it is
      // written once here rather than in each family case, exactly as the
      // radial chain writes it (see _emitRadialGeometry). The four reference
      // marks are not SeriesMarks and structurally have no unit; TrendMark is
      // the only non-series mark this switch can reach.
      if (mark is SeriesMark<_SourceRow>) {
        _optionalString(writer, 'unit', mark.unit);
      }
      // Per-point text, read out of the PLAN rather than off the mark: the four
      // geometry marks that carry `label`/`pointKey` share no intermediate, and
      // `plan.accessors` is already how every other synthesised accessor
      // (open/high/low/close, the scatter channels) reaches this writer. A plan
      // holds an entry only when some point carried a value, so a chart with no
      // per-point text emits neither argument.
      final label = plan.accessors['label'];
      if (label != null) writer.namedArgument('label', label.accessor());
      final pointKey = plan.accessors['pointKey'];
      if (pointKey != null) {
        writer.namedArgument('pointKey', pointKey.accessor());
      }
      // `isXOrdered` is read off the MARK, unlike the two accessors above: it
      // is a plain declared flag, not a synthesised row accessor, so there is
      // nothing in the plan to read. The four families that carry it share no
      // intermediate — `CandlestickMark` is a `SeriesMark` too, but its series
      // hard-codes the flag — so this is a switch rather than a base-class
      // read, and the default arm is what keeps candlestick and trend silent.
      //
      // Written ONLY when true. False is the default on the mark, on the verb
      // and on `ChartSeries`, so a chart that declares nothing must emit
      // exactly the text it emitted before this slice.
      final isXOrdered = switch (mark) {
        LineMark<_SourceRow>() => mark.isXOrdered,
        AreaMark<_SourceRow>() => mark.isXOrdered,
        BarMark<_SourceRow>() => mark.isXOrdered,
        ScatterMark<_SourceRow>() => mark.isXOrdered,
        _ => false,
      };
      if (isXOrdered) writer.namedArgument('isXOrdered', 'true');
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
        case RadialMark<_SourceRow>():
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

  /// Emits `ringIds: {'<ringKey>': '<seriesId>', …}` for a concentric
  /// composition whose captured ids do not follow `'<markId>-<ringKey>'`.
  ///
  /// `ringIds` is a `geomDonut` argument with no config-form counterpart, but
  /// its LITERAL rendering — sorted string keys, string values, the same map
  /// framing `ringWeights:` and `dataLabelsByRing:` use — is not grammar-only,
  /// so it goes through the config emitter's shared map seam rather than
  /// growing a third private copy of that framing here. Every other literal
  /// this chain writes is delegated the same way.
  void _emitRingIds(DartSourceWriter writer, Map<String, String> ringIds) {
    _config.emitStringMapArgument(writer, 'ringIds', ringIds);
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
