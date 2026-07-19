import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_data_payload.dart';
import '../artifacts/chart_document.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/chart_view_state.dart';
import '../artifacts/json_value.dart';
import '../models/data_point_label_config.dart';
import 'chart_table_options.dart';

/// Deprecated table-specific name for the canonical chart point identity.
@Deprecated('Use ChartPointRef instead.')
typedef ChartTablePointReference = ChartPointRef;

/// Additional numeric fields that belong to a Cartesian point without
/// becoming independent chart series.
enum ChartTableAuxiliaryField {
  magnitude,
  colorValue,
  opacityValue,
  rangeStart,
  target,
  errorLower,
  errorUpper,
  stackStart,
  stackEnd,
  waterfallCumulative,
  normalizedShare,
}

extension ChartTableAuxiliaryFieldLabel on ChartTableAuxiliaryField {
  /// Short human-readable heading used by native table and export surfaces.
  String get label => switch (this) {
    ChartTableAuxiliaryField.magnitude => 'Magnitude',
    ChartTableAuxiliaryField.colorValue => 'Color value',
    ChartTableAuxiliaryField.opacityValue => 'Opacity value',
    ChartTableAuxiliaryField.rangeStart => 'Start',
    ChartTableAuxiliaryField.target => 'Target',
    ChartTableAuxiliaryField.errorLower => 'Lower',
    ChartTableAuxiliaryField.errorUpper => 'Upper',
    ChartTableAuxiliaryField.stackStart => 'Stack start',
    ChartTableAuxiliaryField.stackEnd => 'Stack end',
    ChartTableAuxiliaryField.waterfallCumulative => 'Running total',
    ChartTableAuxiliaryField.normalizedShare => 'Share',
  };

  /// Unit that replaces the source series unit for this derived measure.
  String? get unitOverride => switch (this) {
    ChartTableAuxiliaryField.normalizedShare => '%',
    _ => null,
  };
}

/// One display-ready auxiliary value attached to a canonical chart point.
@immutable
class ChartTableAuxiliaryValue {
  const ChartTableAuxiliaryValue({
    required this.raw,
    required this.display,
    required this.isValid,
  });

  final double raw;
  final String display;
  final bool isValid;
}

@immutable
class ChartTableSeriesColumn {
  const ChartTableSeriesColumn({
    required this.seriesId,
    required this.seriesName,
    required this.hidden,
    this.unit,
    this.colorValue,
    this.auxiliaryFields = const {},
  });

  final String seriesId;
  final String seriesName;
  final String? unit;
  final bool hidden;

  /// Effective ARGB color used by the corresponding chart series.
  ///
  /// This resolves an explicit series color first, then the captured chart
  /// theme palette. Keeping the value as an integer preserves the table model's
  /// portable boundary while allowing widgets to render the same visual cue.
  final int? colorValue;

  /// Point-aligned passive measures exposed next to this series' main value.
  final Set<ChartTableAuxiliaryField> auxiliaryFields;
}

/// Canonical, lossless long-form row for one logical chart point.
@immutable
class ChartTableLongRow {
  const ChartTableLongRow({
    required this.rowId,
    required this.reference,
    required this.seriesName,
    required this.xRaw,
    required this.xDisplay,
    required this.yRaw,
    required this.yDisplay,
    required this.isValid,
    required this.hiddenSeries,
    this.unit,
    this.timestamp,
    this.label,
    this.metadata,
    this.auxiliaryValues = const {},
  });

  final String rowId;
  final ChartTablePointReference reference;
  final String seriesName;
  final double xRaw;
  final String xDisplay;
  final double yRaw;
  final String yDisplay;
  final String? unit;
  final DateTime? timestamp;
  final String? label;
  final bool isValid;
  final bool hiddenSeries;
  final JsonObjectValue? metadata;
  final Map<ChartTableAuxiliaryField, ChartTableAuxiliaryValue> auxiliaryValues;
}

@immutable
class ChartTableWideCell {
  const ChartTableWideCell({
    required this.reference,
    required this.yRaw,
    required this.yDisplay,
    required this.isValid,
    this.unit,
    this.timestamp,
    this.label,
    this.metadata,
    this.isDerived = false,
    this.auxiliaryValues = const {},
  });

  final ChartTablePointReference reference;
  final double yRaw;
  final String yDisplay;
  final String? unit;
  final DateTime? timestamp;
  final String? label;
  final bool isValid;
  final JsonObjectValue? metadata;
  final bool isDerived;
  final Map<ChartTableAuxiliaryField, ChartTableAuxiliaryValue> auxiliaryValues;
}

@immutable
class ChartTableWideRow {
  ChartTableWideRow({
    required this.rowId,
    required this.xRaw,
    required this.xDisplay,
    required Map<String, ChartTableWideCell> cells,
  }) : cells = Map.unmodifiable(cells);

  final String rowId;
  final double xRaw;
  final String xDisplay;
  final Map<String, ChartTableWideCell> cells;
}

/// Native categorical projection for one transported radial category slice.
@immutable
class ChartTablePieRow {
  const ChartTablePieRow({
    required this.rowId,
    required this.reference,
    String? seriesId,
    String? seriesName,
    this.ringIndex = 0,
    required this.category,
    required this.valueRaw,
    required this.valueDisplay,
    required this.shareRaw,
    required this.shareDisplay,
    required this.isValid,
    this.unit,
    this.radiusRaw,
    this.radiusDisplay,
    this.radiusLabel,
    this.radiusUnit,
    this.colorValue,
  }) : _seriesId = seriesId,
       _seriesName = seriesName;

  final String rowId;
  final ChartTablePointReference reference;

  /// Stable radial series identity retained by table, selection, and export.
  String get seriesId => _seriesId ?? reference.seriesId;

  final String? _seriesId;

  /// User-facing ring name, falling back to [seriesId].
  String get seriesName => _seriesName ?? seriesId;

  final String? _seriesName;

  /// Zero-based source-series order within the radial document.
  final int ringIndex;

  final String category;
  final double valueRaw;
  final String valueDisplay;

  /// Fractional share in the inclusive range 0–1 for valid radial documents.
  final double shareRaw;

  /// Percentage display with two fractional digits.
  final String shareDisplay;
  final String? unit;

  /// Optional raw second metric used to encode this slice's outer radius.
  final double? radiusRaw;

  /// Two-decimal display value for [radiusRaw].
  final String? radiusDisplay;

  /// Human-readable name for the radius metric.
  final String? radiusLabel;

  /// Optional unit for the radius metric.
  final String? radiusUnit;

  final bool isValid;

  /// Effective ARGB slice color, when the point produces visible geometry.
  final int? colorValue;
}

/// Native category/value projection for one Polar Column mark.
@immutable
class ChartTablePolarRow {
  const ChartTablePolarRow({
    required this.rowId,
    required this.reference,
    required this.seriesId,
    required this.seriesName,
    required this.category,
    required this.valueRaw,
    required this.valueDisplay,
    required this.isValid,
    this.unit,
    this.colorValue,
  });

  final String rowId;
  final ChartTablePointReference reference;
  final String seriesId;
  final String seriesName;
  final String category;
  final double valueRaw;
  final String valueDisplay;
  final String? unit;
  final bool isValid;
  final int? colorValue;
}

/// Renderer-aware shape exposed by a derived chart table.
enum ChartTableProjectionKind {
  /// Canonical one-point-per-row Cartesian projection.
  cartesianLong,

  /// Exact-X Cartesian projection with one value column per series.
  cartesianWide,

  /// Category, value, and share projection for one radial category series.
  pie,

  /// Category, series, and value projection for an axis-based polar series.
  polar,
}

/// Immutable chart-table projection derived exclusively from [ChartDocument].
///
/// [longRows] always remains available as the canonical lossless form. A wide
/// layout is an additional exact-X projection and never replaces raw rows.
@immutable
class ChartTableModel {
  ChartTableModel._({
    required this.documentId,
    required this.documentRevision,
    required this.xColumnLabel,
    required this.projectionKind,
    required this.options,
    required Iterable<ChartTableSeriesColumn> series,
    required Iterable<ChartTableLongRow> longRows,
    required Iterable<ChartTableWideRow> wideRows,
    required Iterable<ChartTablePieRow> pieRows,
    required Iterable<ChartTablePolarRow> polarRows,
    required Iterable<ChartArtifactWarning> warnings,
  }) : series = List.unmodifiable(series),
       longRows = List.unmodifiable(longRows),
       wideRows = List.unmodifiable(wideRows),
       pieRows = List.unmodifiable(pieRows),
       polarRows = List.unmodifiable(polarRows),
       warnings = List.unmodifiable(warnings);

  factory ChartTableModel.fromDocument(
    ChartDocument document, {
    ChartViewState? viewState,
    ChartTableOptions options = const ChartTableOptions(),
  }) {
    final warnings = <ChartArtifactWarning>[];
    final hiddenIds = viewState?.hiddenSeriesIds ?? const <String>{};
    final selected = _selectSeries(document, viewState, options);
    final radialSeries = selected
        .where((series) => series.type == 'pie' || series.type == 'donut')
        .toList();
    final polarSeries = selected
        .where((series) => series.type == 'polarColumn')
        .toList();
    if ((radialSeries.isNotEmpty && radialSeries.length != selected.length) ||
        (polarSeries.isNotEmpty && polarSeries.length != selected.length)) {
      throw UnsupportedError(
        'Radial table projection cannot mix chart families.',
      );
    }
    final projectionKind = radialSeries.isNotEmpty
        ? ChartTableProjectionKind.pie
        : polarSeries.isNotEmpty
        ? ChartTableProjectionKind.polar
        : options.rowLayout == ChartTableRowLayout.long
        ? ChartTableProjectionKind.cartesianLong
        : ChartTableProjectionKind.cartesianWide;
    final xFormatter =
        _resolveFormatter(
          document.xAxis.formatter,
          options.formatters,
          warnings,
          r'$.document.xAxis.formatter',
        ) ??
        _categoryFormatter(document.xAxis.categories);
    final axesById = {for (final axis in document.axes) axis.id: axis};
    final themeSeriesColors = _themeSeriesColors(document);
    final stackComposition = _stackCompositionValues(document, hiddenIds);
    final seriesColumns = <ChartTableSeriesColumn>[];
    final longRows = <ChartTableLongRow>[];
    final pieRows = <ChartTablePieRow>[];
    final polarRows = <ChartTablePolarRow>[];

    for (final series in selected) {
      final inlineAxis = series.inlineAxis?.values;
      final inlineAxisId = inlineAxis?['id']?.toJson();
      final resolvedAxisId = series.axisId ?? inlineAxisId;
      final axis = resolvedAxisId is String
          ? axesById[resolvedAxisId]
          : document.axes.isEmpty
          ? null
          : document.axes.first;
      final inlineUnit = inlineAxis?['unit']?.toJson();
      final unit =
          series.unit ??
          (inlineUnit is String ? inlineUnit : null) ??
          axis?.unit;
      final formatterDocument = inlineAxis?['formatter'];
      final yFormatter = _resolveFormatter(
        formatterDocument is JsonObjectValue
            ? formatterDocument
            : axis?.formatter,
        options.formatters,
        warnings,
        '\$.document.series[${document.series.indexOf(series)}].formatter',
        malformed:
            formatterDocument != null && formatterDocument is! JsonObjectValue,
      );
      final hidden = hiddenIds.contains(series.id);
      seriesColumns.add(
        ChartTableSeriesColumn(
          seriesId: series.id,
          seriesName: series.name ?? series.id,
          unit: unit,
          hidden: hidden,
          colorValue: _effectiveSeriesColor(
            series,
            document.series.indexOf(series),
            themeSeriesColors,
          ),
          auxiliaryFields: _auxiliaryFieldsForSeries(series),
        ),
      );
      final payload = series.data;
      if (payload is! InlineChartDataPayload) {
        throw UnsupportedError(
          'Table generation does not support ${payload.storage} payloads.',
        );
      }
      if (series.type == 'pie' || series.type == 'donut') {
        pieRows.addAll(
          _projectPieRows(
            series,
            payload.points,
            ringIndex: document.series.indexOf(series),
            unit: unit,
            themeSeriesColors: themeSeriesColors,
          ),
        );
      }
      if (series.type == 'polarColumn') {
        polarRows.addAll(
          _projectPolarRows(
            series,
            payload.points,
            unit: unit,
            themeSeriesColors: themeSeriesColors,
          ),
        );
      }
      for (
        var pointIndex = 0;
        pointIndex < payload.points.length;
        pointIndex++
      ) {
        final point = payload.points[pointIndex];
        final x = point.x.asDouble;
        if (!_inViewport(x, viewState, options)) continue;
        final y = point.y.asDouble;
        final reference = ChartTablePointReference(
          seriesId: series.id,
          pointIndex: pointIndex,
        );
        longRows.add(
          ChartTableLongRow(
            rowId: '${Uri.encodeComponent(series.id)}:$pointIndex',
            reference: reference,
            seriesName: series.name ?? series.id,
            xRaw: x,
            xDisplay: series.type == 'polarColumn'
                ? (point.label?.trim().isNotEmpty == true
                      ? point.label!.trim()
                      : 'No category')
                : _displayNumber(x, xFormatter),
            yRaw: y,
            yDisplay: _displayNumber(y, yFormatter),
            unit: unit,
            timestamp: point.timestamp,
            label: point.label,
            isValid: x.isFinite && y.isFinite,
            hiddenSeries: hidden,
            metadata: options.includeMetadata ? point.metadata : null,
            auxiliaryValues: _auxiliaryValuesForPoint(
              series,
              pointIndex,
              formatter: yFormatter,
              stackValue: stackComposition[(series.id, pointIndex)],
            ),
          ),
        );
      }
    }

    return ChartTableModel._(
      documentId: document.documentId,
      documentRevision: document.revision,
      xColumnLabel:
          projectionKind == ChartTableProjectionKind.pie ||
              projectionKind == ChartTableProjectionKind.polar
          ? 'Category'
          : _xColumnLabel(document.xAxis),
      projectionKind: projectionKind,
      options: options,
      series: seriesColumns,
      longRows: longRows,
      wideRows: projectionKind == ChartTableProjectionKind.cartesianWide
          ? _pivotExactX(longRows, seriesColumns)
          : const [],
      pieRows: pieRows,
      polarRows: polarRows,
      warnings: warnings,
    );
  }

  final String documentId;
  final int documentRevision;
  final String xColumnLabel;

  /// Effective renderer-aware projection derived from the document.
  ///
  /// This remains separate from [ChartTableOptions.rowLayout] so adding a new
  /// renderer does not expand the existing public long/wide option enum.
  final ChartTableProjectionKind projectionKind;
  final ChartTableOptions options;
  final List<ChartTableSeriesColumn> series;
  final List<ChartTableLongRow> longRows;
  final List<ChartTableWideRow> wideRows;
  final List<ChartTablePieRow> pieRows;
  final List<ChartTablePolarRow> polarRows;
  final List<ChartArtifactWarning> warnings;

  /// Auxiliary fields present in at least one projected Cartesian series.
  Set<ChartTableAuxiliaryField> get auxiliaryFields => Set.unmodifiable({
    for (final column in series) ...column.auxiliaryFields,
  });

  int get rowCount => switch (projectionKind) {
    ChartTableProjectionKind.cartesianLong => longRows.length,
    ChartTableProjectionKind.cartesianWide => wideRows.length,
    ChartTableProjectionKind.pie => pieRows.length,
    ChartTableProjectionKind.polar => polarRows.length,
  };

  bool get isEmpty => rowCount == 0;

  /// Whether this radial projection contains independent Concentric rings.
  bool get hasMultipleRadialSeries =>
      projectionKind == ChartTableProjectionKind.pie && series.length > 1;

  /// Common unit shared by every radial series, or `null` when units differ.
  String? get commonRadialUnit {
    if ((projectionKind != ChartTableProjectionKind.pie &&
            projectionKind != ChartTableProjectionKind.polar) ||
        series.isEmpty) {
      return null;
    }
    final first = series.first.unit;
    return series.every((column) => column.unit == first) ? first : null;
  }

  /// Whether this Pie projection carries a variable-radius metric.
  bool get hasPieRadiusValues => pieRadiusColumnLabel != null;

  /// Radius column heading, including its unit when one was captured.
  String? get pieRadiusColumnLabel {
    if (projectionKind != ChartTableProjectionKind.pie || pieRows.isEmpty) {
      return null;
    }
    final row = pieRows.where((row) => row.radiusLabel != null).firstOrNull;
    if (row == null) return null;
    final label = row.radiusLabel;
    if (label == null) return null;
    return row.radiusUnit == null ? label : '$label (${row.radiusUnit})';
  }

  String get scopeLabel => switch (options.dataScope) {
    ChartTableDataScope.allSeries => 'All series',
    ChartTableDataScope.visibleSeries => 'Visible series',
    ChartTableDataScope.selectedSeries => 'Selected series',
    ChartTableDataScope.specifiedSeries => 'Specified series',
  };
}

List<ChartTablePolarRow> _projectPolarRows(
  ChartSeriesDocument series,
  List<ChartPointDocument> points, {
  required String? unit,
  required List<int> themeSeriesColors,
}) {
  final explicitSeriesColor = _validColorValue(
    series.style?.values['color']?.toJson(),
  );
  return [
    for (final (pointIndex, point) in points.indexed)
      ChartTablePolarRow(
        rowId: '${Uri.encodeComponent(series.id)}:$pointIndex',
        reference: ChartTablePointReference(
          seriesId: series.id,
          pointIndex: pointIndex,
        ),
        seriesId: series.id,
        seriesName: series.name ?? series.id,
        category: point.label?.trim().isNotEmpty == true
            ? point.label!.trim()
            : 'No category',
        valueRaw: point.y.asDouble,
        valueDisplay: point.y.asDouble.isFinite
            ? point.y.asDouble.toStringAsFixed(2)
            : 'No value',
        unit: unit,
        isValid:
            point.x.asDouble.isFinite &&
            point.x.asDouble == pointIndex.toDouble() &&
            point.y.asDouble.isFinite &&
            point.y.asDouble >= 0 &&
            point.label?.trim().isNotEmpty == true,
        colorValue:
            _validColorValue(point.pointStyle?.values['color']?.toJson()) ??
            explicitSeriesColor ??
            (themeSeriesColors.isEmpty
                ? null
                : themeSeriesColors[pointIndex % themeSeriesColors.length]),
      ),
  ];
}

List<ChartTablePieRow> _projectPieRows(
  ChartSeriesDocument series,
  List<ChartPointDocument> points, {
  required int ringIndex,
  required String? unit,
  required List<int> themeSeriesColors,
}) {
  var total = 0.0;
  for (final point in points) {
    final value = point.y.asDouble;
    if (value.isFinite && value >= 0) total += value;
  }
  final validTotal = total.isFinite && total > 0;
  final explicitSeriesColor = _validColorValue(
    series.style?.values['color']?.toJson(),
  );
  final radiusConfig = series.style?.values['sliceRadiusConfig'];
  final radiusConfigValues = radiusConfig is JsonObjectValue
      ? radiusConfig.values
      : null;
  final radiusLabelValue = radiusConfigValues?['label']?.toJson();
  final radiusUnitValue = radiusConfigValues?['unit']?.toJson();
  final radiusLabel = radiusLabelValue is String ? radiusLabelValue : null;
  final radiusUnit = radiusUnitValue is String ? radiusUnitValue : null;
  final rows = <ChartTablePieRow>[];
  var visibleIndex = 0;
  for (final (pointIndex, point) in points.indexed) {
    final value = point.y.asDouble;
    final category = point.label?.trim();
    final valid =
        point.x.asDouble.isFinite &&
        value.isFinite &&
        value >= 0 &&
        category != null &&
        category.isNotEmpty;
    final share = validTotal && value.isFinite && value >= 0
        ? value / total
        : 0.0;
    final contributesSlice = value.isFinite && value > 0;
    final pointColor = _validColorValue(
      point.pointStyle?.values['color']?.toJson(),
    );
    final rawRadiusValue = point.pointStyle?.values['size']?.toJson();
    final radius = rawRadiusValue is num ? rawRadiusValue.toDouble() : null;
    final radiusIsValid =
        radiusConfigValues == null ||
        (radius != null && radius.isFinite && radius >= 0);
    final colorValue = contributesSlice
        ? pointColor ??
              (visibleIndex == 0 ? explicitSeriesColor : null) ??
              (themeSeriesColors.isEmpty
                  ? null
                  : themeSeriesColors[visibleIndex % themeSeriesColors.length])
        : pointColor;
    if (contributesSlice) visibleIndex++;
    rows.add(
      ChartTablePieRow(
        rowId: '${Uri.encodeComponent(series.id)}:$pointIndex',
        reference: ChartTablePointReference(
          seriesId: series.id,
          pointIndex: pointIndex,
        ),
        seriesId: series.id,
        seriesName: series.name ?? series.id,
        ringIndex: ringIndex,
        category: category == null || category.isEmpty
            ? 'No category'
            : category,
        valueRaw: value,
        valueDisplay: value.isFinite ? value.toStringAsFixed(2) : 'No value',
        shareRaw: share,
        shareDisplay: '${(share * 100).toStringAsFixed(2)}%',
        unit: unit,
        radiusRaw: radius,
        radiusDisplay: radius == null
            ? null
            : (radius.isFinite ? radius.toStringAsFixed(2) : 'No value'),
        radiusLabel: radiusLabel,
        radiusUnit: radiusUnit,
        isValid: valid && radiusIsValid,
        colorValue: colorValue,
      ),
    );
  }
  return rows;
}

List<int> _themeSeriesColors(ChartDocument document) {
  final seriesTheme = document.theme.resolved.values['seriesTheme'];
  if (seriesTheme is! JsonObjectValue) return const [];
  final colors = seriesTheme.values['colors'];
  if (colors is! JsonArrayValue) return const [];
  return [for (final color in colors.values) ?_validColorValue(color.toJson())];
}

int? _effectiveSeriesColor(
  ChartSeriesDocument series,
  int seriesIndex,
  List<int> themeSeriesColors,
) {
  final explicit = _validColorValue(series.style?.values['color']?.toJson());
  if (explicit != null) return explicit;
  if (themeSeriesColors.isEmpty) return null;
  return themeSeriesColors[seriesIndex % themeSeriesColors.length];
}

int? _validColorValue(Object? value) {
  if (value is! num || !value.isFinite || value != value.roundToDouble()) {
    return null;
  }
  final integer = value.toInt();
  return integer >= 0 && integer <= 0xFFFFFFFF ? integer : null;
}

List<ChartSeriesDocument> _selectSeries(
  ChartDocument document,
  ChartViewState? viewState,
  ChartTableOptions options,
) => switch (options.dataScope) {
  ChartTableDataScope.allSeries => document.series,
  ChartTableDataScope.visibleSeries => [
    for (final series in document.series)
      if (!(viewState?.hiddenSeriesIds.contains(series.id) ?? false)) series,
  ],
  ChartTableDataScope.selectedSeries => [
    for (final series in document.series)
      if (series.id == viewState?.selectedSeriesId) series,
  ],
  ChartTableDataScope.specifiedSeries => [
    for (final series in document.series)
      if (options.seriesIds.contains(series.id)) series,
  ],
};

bool _inViewport(
  double x,
  ChartViewState? viewState,
  ChartTableOptions options,
) {
  if (!options.viewportOnly) return true;
  final bounds = viewState?.visibleBounds;
  return bounds != null && x.isFinite && x >= bounds.xMin && x <= bounds.xMax;
}

String Function(double)? _resolveFormatter(
  JsonObjectValue? document,
  ChartFormatterRegistry registry,
  List<ChartArtifactWarning> warnings,
  String path, {
  bool malformed = false,
}) {
  if (malformed) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Formatter descriptor is not an object; raw values are shown.',
        path: path,
      ),
    );
    return null;
  }
  if (document == null) return null;
  try {
    final resolution = registry.resolve(
      ChartFormatterDescriptor.fromDocument(document),
    );
    if (resolution.warning != null) {
      warnings.add(
        ChartArtifactWarning(
          code: resolution.warning!.code,
          message: resolution.warning!.message,
          path: path,
        ),
      );
    }
    var emittedRuntimeWarning = false;
    return (value) {
      try {
        return resolution.formatter(value);
      } on Object catch (error) {
        if (!emittedRuntimeWarning) {
          emittedRuntimeWarning = true;
          warnings.add(
            ChartArtifactWarning(
              code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
              message:
                  'Formatter execution failed ($error); raw values are shown.',
              path: path,
            ),
          );
        }
        return _plainNumber(value);
      }
    };
  } on FormatException catch (error) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: '${error.message} Raw values are shown.',
        path: path,
      ),
    );
    return null;
  }
}

String Function(double)? _categoryFormatter(List<String> categories) {
  if (categories.isEmpty) return null;
  return (value) {
    final index = value.round();
    if ((value - index).abs() > 0.000001 ||
        index < 0 ||
        index >= categories.length) {
      return _plainNumber(value);
    }
    return categories[index];
  };
}

String _displayNumber(double value, String Function(double)? formatter) {
  if (value.isNaN) return 'No value';
  if (value == double.infinity) return 'Positive infinity';
  if (value == double.negativeInfinity) return 'Negative infinity';
  return formatter?.call(value) ?? _plainNumber(value);
}

String _plainNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

String _xColumnLabel(ChartAxisDocument axis) {
  final label = axis.label?.trim();
  final unit = axis.unit?.trim();
  if (label != null && label.isNotEmpty) {
    return unit == null || unit.isEmpty ? label : '$label ($unit)';
  }
  return unit == null || unit.isEmpty ? 'X value' : unit;
}

Set<ChartTableAuxiliaryField> _auxiliaryFieldsForSeries(
  ChartSeriesDocument series,
) {
  if (series.type == 'scatter') {
    return Set.unmodifiable({
      if (series.style?.values['sizeEncoding'] is JsonObjectValue)
        ChartTableAuxiliaryField.magnitude,
      if (series.style?.values['colorEncoding'] is JsonObjectValue)
        ChartTableAuxiliaryField.colorValue,
      if (series.style?.values['opacityEncoding'] is JsonObjectValue)
        ChartTableAuxiliaryField.opacityValue,
    });
  }
  if (series.type != 'bar') return const {};
  final style = series.style?.values;
  if (style == null) return const {};
  return Set.unmodifiable({
    if (style['barRangeStartValues'] is JsonArrayValue)
      ChartTableAuxiliaryField.rangeStart,
    if (style['barTargetValues'] is JsonArrayValue)
      ChartTableAuxiliaryField.target,
    if (style['barErrorLowerValues'] is JsonArrayValue)
      ChartTableAuxiliaryField.errorLower,
    if (style['barErrorUpperValues'] is JsonArrayValue)
      ChartTableAuxiliaryField.errorUpper,
    if (style['barLayoutMode'] case final JsonStringValue mode
        when mode.value == 'stacked' || mode.value == 'divergingStacked') ...{
      ChartTableAuxiliaryField.stackStart,
      ChartTableAuxiliaryField.stackEnd,
    },
    if (style['barLayoutMode'] case final JsonStringValue mode
        when mode.value == 'waterfall')
      ChartTableAuxiliaryField.waterfallCumulative,
    if (style['barLayoutMode'] case final JsonStringValue mode
        when mode.value == 'normalizedStacked' ||
            mode.value == 'divergingStacked')
      ChartTableAuxiliaryField.normalizedShare,
  });
}

Map<ChartTableAuxiliaryField, ChartTableAuxiliaryValue>
_auxiliaryValuesForPoint(
  ChartSeriesDocument series,
  int pointIndex, {
  required String Function(double)? formatter,
  _BarStackTableValue? stackValue,
}) {
  if (series.type == 'scatter') {
    final payload = series.data;
    if (payload is! InlineChartDataPayload ||
        pointIndex >= payload.points.length) {
      return const {};
    }
    final values = <ChartTableAuxiliaryField, ChartTableAuxiliaryValue>{};
    final point = payload.points[pointIndex];

    void addScatterValue(
      ChartTableAuxiliaryField field,
      ChartNumberDocument? document,
      String encodingKey, {
      required bool Function(double value) isValid,
    }) {
      final value = document?.asDouble;
      if (value == null) return;
      final encoding = series.style?.values[encodingKey];
      final unit = encoding is JsonObjectValue
          ? encoding.values['unit']?.toJson()
          : null;
      final baseDisplay = _displayNumber(value, null);
      values[field] = ChartTableAuxiliaryValue(
        raw: value,
        display: unit is String && unit.isNotEmpty
            ? '$baseDisplay $unit'
            : baseDisplay,
        isValid: isValid(value),
      );
    }

    addScatterValue(
      ChartTableAuxiliaryField.magnitude,
      point.magnitude,
      'sizeEncoding',
      isValid: (value) => value.isFinite && value >= 0,
    );
    addScatterValue(
      ChartTableAuxiliaryField.colorValue,
      point.colorValue,
      'colorEncoding',
      isValid: (value) => value.isFinite,
    );
    addScatterValue(
      ChartTableAuxiliaryField.opacityValue,
      point.opacityValue,
      'opacityEncoding',
      isValid: (value) => value.isFinite,
    );
    return Map.unmodifiable(values);
  }
  if (series.type != 'bar') return const {};
  final style = series.style?.values;
  if (style == null) return const {};
  final values = <ChartTableAuxiliaryField, ChartTableAuxiliaryValue>{};

  void add(
    ChartTableAuxiliaryField field,
    String styleKey, {
    bool useBaselineForNull = false,
  }) {
    final array = style[styleKey];
    if (array is! JsonArrayValue || pointIndex >= array.values.length) return;
    var raw = _chartNumber(array.values[pointIndex]);
    if (raw == null && useBaselineForNull) {
      raw = _chartNumber(style['baselineValue']);
    }
    if (raw == null) return;
    values[field] = ChartTableAuxiliaryValue(
      raw: raw,
      display: _displayNumber(raw, formatter),
      isValid: raw.isFinite,
    );
  }

  add(
    ChartTableAuxiliaryField.rangeStart,
    'barRangeStartValues',
    useBaselineForNull: true,
  );
  add(ChartTableAuxiliaryField.target, 'barTargetValues');
  add(ChartTableAuxiliaryField.errorLower, 'barErrorLowerValues');
  add(ChartTableAuxiliaryField.errorUpper, 'barErrorUpperValues');
  final mode = style['barLayoutMode'];
  if (mode is JsonStringValue &&
      (mode.value == 'stacked' || mode.value == 'divergingStacked') &&
      stackValue != null) {
    values[ChartTableAuxiliaryField.stackStart] = ChartTableAuxiliaryValue(
      raw: stackValue.start,
      display: _displayNumber(stackValue.start, formatter),
      isValid: stackValue.start.isFinite,
    );
    values[ChartTableAuxiliaryField.stackEnd] = ChartTableAuxiliaryValue(
      raw: stackValue.end,
      display: _displayNumber(stackValue.end, formatter),
      isValid: stackValue.end.isFinite,
    );
  }
  if (_waterfallCumulativeValue(series, pointIndex, style) case final raw?) {
    values[ChartTableAuxiliaryField.waterfallCumulative] =
        ChartTableAuxiliaryValue(
          raw: raw,
          display: _displayNumber(raw, formatter),
          isValid: raw.isFinite,
        );
  }
  if (stackValue?.share case final raw?) {
    values[ChartTableAuxiliaryField.normalizedShare] = ChartTableAuxiliaryValue(
      raw: raw,
      display: DataPointLabelConfig.autoFormatLabelValue(raw, null),
      isValid: raw.isFinite,
    );
  }
  return Map.unmodifiable(values);
}

typedef _BarStackTableValue = ({double start, double end, double? share});

Map<(String, int), _BarStackTableValue> _stackCompositionValues(
  ChartDocument document,
  Set<String> hiddenSeriesIds,
) {
  final stacks =
      <
        (String, String, double, String),
        List<(ChartSeriesDocument, InlineChartDataPayload)>
      >{};
  for (final series in document.series) {
    if (series.type != 'bar' || hiddenSeriesIds.contains(series.id)) continue;
    final style = series.style?.values;
    final payload = series.data;
    if (style == null || payload is! InlineChartDataPayload) continue;
    final mode = style['barLayoutMode'];
    if (mode is! JsonStringValue ||
        (mode.value != 'stacked' &&
            mode.value != 'normalizedStacked' &&
            mode.value != 'divergingStacked')) {
      continue;
    }
    final inlineAxisId = series.inlineAxis?.values['id']?.toJson();
    final axisId =
        series.axisId ??
        (inlineAxisId is String ? inlineAxisId : '__default__');
    final baseline = _chartNumber(style['baselineValue']) ?? 0;
    final groupValue = style['barGroupId']?.toJson();
    final groupId = groupValue is String ? groupValue : '__default__';
    stacks.putIfAbsent((mode.value, axisId, baseline, groupId), () => []).add((
      series,
      payload,
    ));
  }

  final values = <(String, int), _BarStackTableValue>{};
  for (final entry in stacks.entries) {
    if (entry.key.$1 == 'divergingStacked') {
      _appendDivergingTableValues(entry.value, entry.key.$3, values);
      continue;
    }
    final normalized = entry.key.$1 == 'normalizedStacked';
    final baseline = entry.key.$3;
    final positiveTotals = <double, double>{};
    final negativeTotals = <double, double>{};
    if (normalized) {
      for (final item in entry.value) {
        for (final point in item.$2.points) {
          final x = point.x.asDouble;
          final delta = point.y.asDouble - baseline;
          final totals = delta >= 0 ? positiveTotals : negativeTotals;
          totals[x] = (totals[x] ?? 0) + delta.abs();
        }
      }
    }
    final positiveOffsets = <double, double>{};
    final negativeOffsets = <double, double>{};
    for (final item in entry.value) {
      for (final (pointIndex, point) in item.$2.points.indexed) {
        final x = point.x.asDouble;
        final rawDelta = point.y.asDouble - baseline;
        double? share;
        var displayDelta = rawDelta;
        if (normalized) {
          final total = rawDelta >= 0
              ? positiveTotals[x] ?? 0
              : negativeTotals[x] ?? 0;
          share = total == 0 ? 0 : rawDelta / total * 100;
          displayDelta = share;
        }
        final offsets = displayDelta >= 0 ? positiveOffsets : negativeOffsets;
        final start = baseline + (offsets[x] ?? 0);
        final end = start + displayDelta;
        offsets[x] = end - baseline;
        values[(item.$1.id, pointIndex)] = (
          start: start,
          end: end,
          share: share,
        );
      }
    }
  }
  return values;
}

void _appendDivergingTableValues(
  List<(ChartSeriesDocument, InlineChartDataPayload)> series,
  double baseline,
  Map<(String, int), _BarStackTableValue> values,
) {
  final totals = <double, double>{};
  for (final item in series) {
    for (final point in item.$2.points) {
      totals[point.x.asDouble] =
          (totals[point.x.asDouble] ?? 0) + (point.y.asDouble - baseline);
    }
  }

  String roleOf(ChartSeriesDocument document) {
    final value = document.style?.values['barDivergingRole'];
    return value is JsonStringValue ? value.value : 'positive';
  }

  final neutral = series
      .where((item) => roleOf(item.$1) == 'neutral')
      .firstOrNull;
  final xValues = <double>{
    for (final item in series)
      for (final point in item.$2.points) point.x.asDouble,
  };
  for (final x in xValues) {
    double shareFor(
      (ChartSeriesDocument, InlineChartDataPayload) item,
      int pointIndex,
    ) {
      final total = totals[x] ?? 0;
      if (total == 0) return 0;
      final share =
          (item.$2.points[pointIndex].y.asDouble - baseline) / total * 100;
      final rounded = share.roundToDouble();
      return (share - rounded).abs() < 1e-10 ? rounded : share;
    }

    final neutralIndex = neutral?.$2.points.indexWhere(
      (point) => point.x.asDouble == x,
    );
    final neutralShare =
        neutral == null || neutralIndex == null || neutralIndex < 0
        ? 0.0
        : shareFor(neutral, neutralIndex);
    if (neutral != null && neutralIndex != null && neutralIndex >= 0) {
      values[(neutral.$1.id, neutralIndex)] = (
        start: baseline - neutralShare / 2,
        end: baseline + neutralShare / 2,
        share: neutralShare,
      );
    }

    var negativeOffset = -neutralShare / 2;
    for (final item
        in series
            .where((current) => roleOf(current.$1) == 'negative')
            .toList(growable: false)
            .reversed) {
      final pointIndex = item.$2.points.indexWhere(
        (point) => point.x.asDouble == x,
      );
      if (pointIndex < 0) continue;
      final share = shareFor(item, pointIndex);
      final start = negativeOffset;
      negativeOffset -= share;
      values[(item.$1.id, pointIndex)] = (
        start: baseline + start,
        end: baseline + negativeOffset,
        share: share,
      );
    }

    var positiveOffset = neutralShare / 2;
    for (final item in series.where(
      (current) => roleOf(current.$1) == 'positive',
    )) {
      final pointIndex = item.$2.points.indexWhere(
        (point) => point.x.asDouble == x,
      );
      if (pointIndex < 0) continue;
      final share = shareFor(item, pointIndex);
      final start = positiveOffset;
      positiveOffset += share;
      values[(item.$1.id, pointIndex)] = (
        start: baseline + start,
        end: baseline + positiveOffset,
        share: share,
      );
    }
  }
}

double? _waterfallCumulativeValue(
  ChartSeriesDocument series,
  int pointIndex,
  Map<String, JsonValue> style,
) {
  final mode = style['barLayoutMode'];
  if (mode is! JsonStringValue || mode.value != 'waterfall') return null;
  final payload = series.data;
  if (payload is! InlineChartDataPayload ||
      pointIndex >= payload.points.length) {
    return null;
  }
  final totalIndices = <int>{};
  if (style['barWaterfallTotalIndices'] case final JsonArrayValue indices) {
    for (final value in indices.values) {
      final raw = value.toJson();
      if (raw is int) totalIndices.add(raw);
    }
  }
  var running = _chartNumber(style['baselineValue']) ?? 0;
  for (var index = 0; index <= pointIndex; index++) {
    if (!totalIndices.contains(index)) {
      running += payload.points[index].y.asDouble;
    }
  }
  return running;
}

double? _chartNumber(JsonValue? value) {
  if (value == null || value is JsonNullValue) return null;
  try {
    return ChartNumberDocument.fromJson(value.toJson()).asDouble;
  } on FormatException {
    return null;
  }
}

List<ChartTableWideRow> _pivotExactX(
  List<ChartTableLongRow> longRows,
  List<ChartTableSeriesColumn> columns,
) {
  final occurrenceBySeriesAndX = <String, Map<String, int>>{};
  final rows = <String, _MutableWideRow>{};
  for (final row in longRows) {
    final xKey = canonicalJsonEncode(
      ChartNumberDocument.fromDouble(row.xRaw).toJson(),
    );
    final occurrences = occurrenceBySeriesAndX.putIfAbsent(
      row.reference.seriesId,
      () => {},
    );
    final occurrence = occurrences.update(
      xKey,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final pivotKey = '$xKey#$occurrence';
    final wide = rows.putIfAbsent(
      pivotKey,
      () => _MutableWideRow(
        rowId: 'x:${Uri.encodeComponent(xKey)}:$occurrence',
        xRaw: row.xRaw,
        xDisplay: row.xDisplay,
      ),
    );
    wide.cells[row.reference.seriesId] = ChartTableWideCell(
      reference: row.reference,
      yRaw: row.yRaw,
      yDisplay: row.yDisplay,
      unit: row.unit,
      timestamp: row.timestamp,
      label: row.label,
      isValid: row.isValid,
      metadata: row.metadata,
      auxiliaryValues: row.auxiliaryValues,
    );
  }
  final knownIds = columns.map((column) => column.seriesId).toSet();
  return [
    for (final row in rows.values)
      ChartTableWideRow(
        rowId: row.rowId,
        xRaw: row.xRaw,
        xDisplay: row.xDisplay,
        cells: {
          for (final entry in row.cells.entries)
            if (knownIds.contains(entry.key)) entry.key: entry.value,
        },
      ),
  ];
}

class _MutableWideRow {
  _MutableWideRow({
    required this.rowId,
    required this.xRaw,
    required this.xDisplay,
  });

  final String rowId;
  final double xRaw;
  final String xDisplay;
  final Map<String, ChartTableWideCell> cells = {};
}
