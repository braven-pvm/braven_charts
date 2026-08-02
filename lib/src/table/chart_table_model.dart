import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_data_payload.dart';
import '../artifacts/chart_document.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/chart_view_state.dart';
import '../artifacts/json_value.dart';
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
  rangeLow,
  rangeHigh,
  rangeSpan,
  rangeStart,
  target,
  errorLower,
  errorUpper,
  stackStart,
  stackEnd,
  waterfallCumulative,
  normalizedShare,
  heatmapRowCoordinate,
  heatmapXMinimum,
  heatmapXMaximum,
  heatmapYMinimum,
  heatmapYMaximum,
}

extension ChartTableAuxiliaryFieldLabel on ChartTableAuxiliaryField {
  /// Short human-readable heading used by native table and export surfaces.
  String get label => switch (this) {
    ChartTableAuxiliaryField.magnitude => 'Magnitude',
    ChartTableAuxiliaryField.colorValue => 'Color value',
    ChartTableAuxiliaryField.opacityValue => 'Opacity value',
    ChartTableAuxiliaryField.rangeLow => 'Low',
    ChartTableAuxiliaryField.rangeHigh => 'High',
    ChartTableAuxiliaryField.rangeSpan => 'Span',
    ChartTableAuxiliaryField.rangeStart => 'Start',
    ChartTableAuxiliaryField.target => 'Target',
    ChartTableAuxiliaryField.errorLower => 'Lower',
    ChartTableAuxiliaryField.errorUpper => 'Upper',
    ChartTableAuxiliaryField.stackStart => 'Stack start',
    ChartTableAuxiliaryField.stackEnd => 'Stack end',
    ChartTableAuxiliaryField.waterfallCumulative => 'Running total',
    ChartTableAuxiliaryField.normalizedShare => 'Share',
    ChartTableAuxiliaryField.heatmapRowCoordinate => 'Y',
    ChartTableAuxiliaryField.heatmapXMinimum => 'X min',
    ChartTableAuxiliaryField.heatmapXMaximum => 'X max',
    ChartTableAuxiliaryField.heatmapYMinimum => 'Y min',
    ChartTableAuxiliaryField.heatmapYMaximum => 'Y max',
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
    this.categoryLabel,
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

  /// Categorical Scatter field heading, when one is encoded by this series.
  final String? categoryLabel;

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
    this.categoryValue,
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
  final String? categoryValue;
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
    this.categoryValue,
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
  final String? categoryValue;
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
    this.targetRaw,
    this.targetDisplay,
    this.intervalLowerRaw,
    this.intervalLowerDisplay,
    this.intervalUpperRaw,
    this.intervalUpperDisplay,
  });

  final String rowId;
  final ChartTablePointReference reference;
  final String seriesId;
  final String seriesName;
  final String category;
  final double valueRaw;
  final String valueDisplay;
  final String? unit;
  final double? targetRaw;
  final String? targetDisplay;
  final double? intervalLowerRaw;
  final String? intervalLowerDisplay;
  final double? intervalUpperRaw;
  final String? intervalUpperDisplay;
  final bool isValid;
  final int? colorValue;
}

/// Native one-measurement projection for a Gauge or Solid Gauge.
@immutable
class ChartTableGaugeRow {
  const ChartTableGaugeRow({
    required this.rowId,
    required this.reference,
    required this.seriesId,
    required this.metric,
    required this.valueRaw,
    required this.valueDisplay,
    required this.minimumRaw,
    required this.minimumDisplay,
    required this.maximumRaw,
    required this.maximumDisplay,
    required this.progressRaw,
    required this.progressDisplay,
    required this.isValid,
    this.unit,
    this.targetRaw,
    this.targetDisplay,
    this.status,
  });

  final String rowId;
  final ChartTablePointReference reference;
  final String seriesId;
  final String metric;
  final double valueRaw;
  final String valueDisplay;
  final double minimumRaw;
  final String minimumDisplay;
  final double maximumRaw;
  final String maximumDisplay;
  final double progressRaw;
  final String progressDisplay;
  final String? unit;
  final double? targetRaw;
  final String? targetDisplay;
  final String? status;
  final bool isValid;
}

/// Native financial projection for one source candlestick and exact-X overlays.
@immutable
class ChartTableCandlestickRow {
  ChartTableCandlestickRow({
    required this.rowId,
    required this.reference,
    required this.xRaw,
    required this.xDisplay,
    required this.openRaw,
    required this.openDisplay,
    required this.highRaw,
    required this.highDisplay,
    required this.lowRaw,
    required this.lowDisplay,
    required this.closeRaw,
    required this.closeDisplay,
    required this.changeRaw,
    required this.changeDisplay,
    required this.changePercentRaw,
    required this.changePercentDisplay,
    required this.isValid,
    required this.hiddenSeries,
    required Map<String, ChartTableWideCell> overlayCells,
    this.unit,
    this.timestamp,
    this.label,
  }) : overlayCells = Map.unmodifiable(overlayCells);

  final String rowId;
  final ChartTablePointReference reference;
  final double xRaw;
  final String xDisplay;
  final DateTime? timestamp;
  final double openRaw;
  final String openDisplay;
  final double highRaw;
  final String highDisplay;
  final double lowRaw;
  final String lowDisplay;
  final double closeRaw;
  final String closeDisplay;
  final double changeRaw;
  final String changeDisplay;
  final double? changePercentRaw;
  final String changePercentDisplay;
  final String? unit;
  final String? label;
  final bool isValid;
  final bool hiddenSeries;

  /// Values from permitted Line, Area, or Scatter overlays at this exact X.
  final Map<String, ChartTableWideCell> overlayCells;
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

  /// One operational measurement against an explicit Gauge domain.
  gauge,

  /// Time/X, OHLC, price-change, and exact-X Cartesian overlay projection.
  candlestick,
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
    required Iterable<ChartTableGaugeRow> gaugeRows,
    required Iterable<ChartTableCandlestickRow> candlestickRows,
    required Iterable<ChartArtifactWarning> warnings,
  }) : series = List.unmodifiable(series),
       longRows = List.unmodifiable(longRows),
       wideRows = List.unmodifiable(wideRows),
       pieRows = List.unmodifiable(pieRows),
       polarRows = List.unmodifiable(polarRows),
       gaugeRows = List.unmodifiable(gaugeRows),
       candlestickRows = List.unmodifiable(candlestickRows),
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
        .where(
          (series) =>
              series.type == 'polarColumn' || series.type == 'radialBar',
        )
        .toList();
    final candlestickSeries = selected
        .where((series) => series.type == 'candlestick')
        .toList();
    final gaugeSeries = selected
        .where((series) => series.type == 'gauge')
        .toList();
    final heatmapSeries = selected
        .where((series) => series.type == 'heatmap')
        .toList();
    if (heatmapSeries.isNotEmpty &&
        selected.any(
          (series) => series.type != 'heatmap' && series.type != 'line',
        )) {
      throw UnsupportedError(
        'Heatmap tables only support Line contour overlays.',
      );
    }
    final hasHeatmapOverlays =
        heatmapSeries.isNotEmpty && heatmapSeries.length != selected.length;
    final hasMultipleHeatmaps = heatmapSeries.length > 1;
    final hasIrregularHeatmap = heatmapSeries.any(
      _heatmapSeriesHasExplicitBounds,
    );
    if (gaugeSeries.length > 1) {
      throw UnsupportedError(
        'Gauge table projection supports exactly one measurement.',
      );
    }
    if (gaugeSeries.isNotEmpty && gaugeSeries.length != selected.length) {
      throw UnsupportedError(
        'Gauge table projection cannot mix chart families.',
      );
    }
    if (candlestickSeries.length > 1) {
      throw UnsupportedError(
        'Candlestick table projection supports exactly one OHLC series.',
      );
    }
    if (candlestickSeries.isNotEmpty &&
        selected.any(
          (series) =>
              series.type != 'candlestick' &&
              series.type != 'line' &&
              series.type != 'area' &&
              series.type != 'scatter',
        )) {
      throw UnsupportedError(
        'Candlestick tables only support Line, Area, or Scatter overlays.',
      );
    }
    if ((radialSeries.isNotEmpty && radialSeries.length != selected.length) ||
        (polarSeries.isNotEmpty && polarSeries.length != selected.length)) {
      throw UnsupportedError(
        'Radial table projection cannot mix chart families.',
      );
    }
    final projectionKind = candlestickSeries.isNotEmpty
        ? ChartTableProjectionKind.candlestick
        : gaugeSeries.isNotEmpty
        ? ChartTableProjectionKind.gauge
        : radialSeries.isNotEmpty
        ? ChartTableProjectionKind.pie
        : polarSeries.isNotEmpty
        ? ChartTableProjectionKind.polar
        : hasHeatmapOverlays ||
              hasMultipleHeatmaps ||
              hasIrregularHeatmap ||
              options.rowLayout == ChartTableRowLayout.long
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
    final gaugeRows = <ChartTableGaugeRow>[];
    final unitsBySeries = <String, String?>{};
    final formattersBySeries = <String, String Function(double)?>{};
    final hiddenBySeries = <String, bool>{};

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
      final heatmapYFormatter = series.type == 'heatmap'
          ? _categoryFormatter(axis?.categories ?? const [])
          : null;
      final hidden = hiddenIds.contains(series.id);
      unitsBySeries[series.id] = unit;
      formattersBySeries[series.id] = yFormatter;
      hiddenBySeries[series.id] = hidden;
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
          categoryLabel: _categoryLabelForSeries(series),
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
      if (series.type == 'polarColumn' || series.type == 'radialBar') {
        polarRows.addAll(
          _projectPolarRows(
            series,
            payload.points,
            unit: unit,
            themeSeriesColors: themeSeriesColors,
          ),
        );
      }
      if (series.type == 'gauge') {
        gaugeRows.addAll(
          _projectGaugeRows(
            series,
            payload.points,
            unit: unit,
            formatter: yFormatter,
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
        final rangeArea = series.type == 'rangeArea'
            ? _rangeAreaValues(point)
            : null;
        final heatmap = series.type == 'heatmap'
            ? _heatmapCellValues(point)
            : null;
        final y = heatmap != null
            ? heatmap.value ?? double.nan
            : rangeArea?.isGap == true
            ? double.nan
            : point.y.asDouble;
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
            xDisplay: series.type == 'polarColumn' || series.type == 'radialBar'
                ? (point.label?.trim().isNotEmpty == true
                      ? point.label!.trim()
                      : 'No category')
                : _displayNumber(x, xFormatter),
            yRaw: y,
            yDisplay: heatmap?.isMissing == true
                ? 'Missing'
                : _displayNumber(y, yFormatter),
            unit: unit,
            timestamp: point.timestamp,
            label: point.label,
            categoryValue: point.categoryValue,
            isValid:
                x.isFinite &&
                y.isFinite &&
                (heatmap == null || !heatmap.isMissing),
            hiddenSeries: hidden,
            metadata: options.includeMetadata ? point.metadata : null,
            auxiliaryValues: {
              ..._auxiliaryValuesForPoint(
                series,
                pointIndex,
                formatter: yFormatter,
                stackValue: stackComposition[(series.id, pointIndex)],
              ),
              if (heatmap != null)
                ChartTableAuxiliaryField
                    .heatmapRowCoordinate: ChartTableAuxiliaryValue(
                  raw: point.y.asDouble,
                  display: _displayNumber(point.y.asDouble, heatmapYFormatter),
                  isValid: point.y.asDouble.isFinite,
                ),
              if (heatmap?.bounds case final bounds?) ...{
                ChartTableAuxiliaryField.heatmapXMinimum:
                    ChartTableAuxiliaryValue(
                      raw: bounds.xMinimum,
                      display: _displayNumber(bounds.xMinimum, xFormatter),
                      isValid: bounds.xMinimum.isFinite,
                    ),
                ChartTableAuxiliaryField.heatmapXMaximum:
                    ChartTableAuxiliaryValue(
                      raw: bounds.xMaximum,
                      display: _displayNumber(bounds.xMaximum, xFormatter),
                      isValid: bounds.xMaximum.isFinite,
                    ),
                ChartTableAuxiliaryField
                    .heatmapYMinimum: ChartTableAuxiliaryValue(
                  raw: bounds.yMinimum,
                  display: _displayNumber(bounds.yMinimum, heatmapYFormatter),
                  isValid: bounds.yMinimum.isFinite,
                ),
                ChartTableAuxiliaryField
                    .heatmapYMaximum: ChartTableAuxiliaryValue(
                  raw: bounds.yMaximum,
                  display: _displayNumber(bounds.yMaximum, heatmapYFormatter),
                  isValid: bounds.yMaximum.isFinite,
                ),
              },
            },
          ),
        );
      }
    }

    final candlestickRows = candlestickSeries.isEmpty
        ? const <ChartTableCandlestickRow>[]
        : _projectCandlestickRows(
            candlestickSeries.single,
            selected,
            xFormatter: xFormatter,
            formattersBySeries: formattersBySeries,
            unitsBySeries: unitsBySeries,
            hiddenBySeries: hiddenBySeries,
            viewState: viewState,
            options: options,
          );
    final projectedSeriesColumns =
        heatmapSeries.isNotEmpty &&
            projectionKind == ChartTableProjectionKind.cartesianWide
        ? _heatmapMatrixColumns(
            longRows,
            unit: heatmapSeries.single.unit,
            hidden: hiddenIds.contains(heatmapSeries.single.id),
          )
        : candlestickSeries.isEmpty
        ? seriesColumns
        : <ChartTableSeriesColumn>[
            seriesColumns.firstWhere(
              (column) => column.seriesId == candlestickSeries.single.id,
            ),
            ...seriesColumns.where(
              (column) => column.seriesId != candlestickSeries.single.id,
            ),
          ];

    return ChartTableModel._(
      documentId: document.documentId,
      documentRevision: document.revision,
      xColumnLabel:
          projectionKind == ChartTableProjectionKind.pie ||
              projectionKind == ChartTableProjectionKind.polar
          ? 'Category'
          : projectionKind == ChartTableProjectionKind.gauge
          ? 'Metric'
          : heatmapSeries.isNotEmpty &&
                projectionKind == ChartTableProjectionKind.cartesianWide
          ? 'Y \\ X'
          : _xColumnLabel(document.xAxis),
      projectionKind: projectionKind,
      options: options,
      series: projectedSeriesColumns,
      longRows: longRows,
      wideRows: projectionKind == ChartTableProjectionKind.cartesianWide
          ? heatmapSeries.isNotEmpty
                ? _pivotHeatmapMatrix(longRows, projectedSeriesColumns)
                : _pivotExactX(longRows, seriesColumns)
          : const [],
      pieRows: pieRows,
      polarRows: polarRows,
      gaugeRows: gaugeRows,
      candlestickRows: candlestickRows,
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
  final List<ChartTableGaugeRow> gaugeRows;
  final List<ChartTableCandlestickRow> candlestickRows;
  final List<ChartArtifactWarning> warnings;

  /// Auxiliary fields present in at least one projected Cartesian series.
  Set<ChartTableAuxiliaryField> get auxiliaryFields => Set.unmodifiable({
    for (final column in series) ...column.auxiliaryFields,
  });

  bool get hasCategoryValues =>
      series.any((column) => column.categoryLabel != null);

  int get rowCount => switch (projectionKind) {
    ChartTableProjectionKind.cartesianLong => longRows.length,
    ChartTableProjectionKind.cartesianWide => wideRows.length,
    ChartTableProjectionKind.pie => pieRows.length,
    ChartTableProjectionKind.polar => polarRows.length,
    ChartTableProjectionKind.gauge => gaugeRows.length,
    ChartTableProjectionKind.candlestick => candlestickRows.length,
  };

  bool get isEmpty => rowCount == 0;

  /// Whether this radial projection contains independent Concentric rings.
  bool get hasMultipleRadialSeries =>
      projectionKind == ChartTableProjectionKind.pie && series.length > 1;

  /// Whether at least one Polar Column row carries an absolute target.
  bool get hasPolarTargets =>
      projectionKind == ChartTableProjectionKind.polar &&
      polarRows.any((row) => row.targetRaw != null);

  /// Whether at least one Polar Column row carries an absolute interval.
  bool get hasPolarIntervals =>
      projectionKind == ChartTableProjectionKind.polar &&
      polarRows.any(
        (row) => row.intervalLowerRaw != null && row.intervalUpperRaw != null,
      );

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
  final rawTargets = series.style?.values['polarTargetValues']?.toJson();
  final targetValues = rawTargets is List ? rawTargets : const <Object?>[];
  final rawIntervalLowers = series.style?.values['polarIntervalLowerValues']
      ?.toJson();
  final intervalLowerValues = rawIntervalLowers is List
      ? rawIntervalLowers
      : const <Object?>[];
  final rawIntervalUppers = series.style?.values['polarIntervalUpperValues']
      ?.toJson();
  final intervalUpperValues = rawIntervalUppers is List
      ? rawIntervalUppers
      : const <Object?>[];
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
        targetRaw:
            pointIndex < targetValues.length && targetValues[pointIndex] is num
            ? (targetValues[pointIndex] as num).toDouble()
            : null,
        targetDisplay:
            pointIndex < targetValues.length && targetValues[pointIndex] is num
            ? (targetValues[pointIndex] as num).toDouble().toStringAsFixed(2)
            : null,
        intervalLowerRaw:
            pointIndex < intervalLowerValues.length &&
                intervalLowerValues[pointIndex] is num
            ? (intervalLowerValues[pointIndex] as num).toDouble()
            : null,
        intervalLowerDisplay:
            pointIndex < intervalLowerValues.length &&
                intervalLowerValues[pointIndex] is num
            ? (intervalLowerValues[pointIndex] as num)
                  .toDouble()
                  .toStringAsFixed(2)
            : null,
        intervalUpperRaw:
            pointIndex < intervalUpperValues.length &&
                intervalUpperValues[pointIndex] is num
            ? (intervalUpperValues[pointIndex] as num).toDouble()
            : null,
        intervalUpperDisplay:
            pointIndex < intervalUpperValues.length &&
                intervalUpperValues[pointIndex] is num
            ? (intervalUpperValues[pointIndex] as num)
                  .toDouble()
                  .toStringAsFixed(2)
            : null,
        unit: unit,
        isValid:
            point.x.asDouble.isFinite &&
            point.x.asDouble == pointIndex.toDouble() &&
            point.y.asDouble.isFinite &&
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

List<ChartTableGaugeRow> _projectGaugeRows(
  ChartSeriesDocument series,
  List<ChartPointDocument> points, {
  required String? unit,
  required String Function(double)? formatter,
}) {
  if (points.length != 1) {
    throw const FormatException(
      'Gauge table projection requires one canonical measurement point.',
    );
  }
  final style = series.style?.values;
  if (style == null) {
    throw const FormatException(
      'Gauge table projection requires Gauge series style data.',
    );
  }
  final metricValue = style['gaugeMetric']?.toJson();
  final minimumValue = style['gaugeMinimum']?.toJson();
  final maximumValue = style['gaugeMaximum']?.toJson();
  if (metricValue is! String ||
      metricValue.trim().isEmpty ||
      minimumValue is! num ||
      maximumValue is! num) {
    throw const FormatException('Gauge table style data is incomplete.');
  }
  final point = points.single;
  final value = point.y.asDouble;
  final minimum = minimumValue.toDouble();
  final maximum = maximumValue.toDouble();
  final valid =
      value.isFinite &&
      minimum.isFinite &&
      maximum.isFinite &&
      minimum < maximum &&
      value >= minimum &&
      value <= maximum;
  final progress = valid ? (value - minimum) / (maximum - minimum) : double.nan;
  final targetJson = style['gaugeTarget']?.toJson();
  final targetMap = targetJson is Map ? targetJson : null;
  final targetValue = targetMap?['value'];
  final target = targetValue is num ? targetValue.toDouble() : null;
  final zonesJson = style['gaugeZones']?.toJson();
  String? status;
  if (zonesJson is List) {
    for (final zone in zonesJson.whereType<Map>()) {
      final from = zone['from'];
      final to = zone['to'];
      final zoneStatus = zone['status'];
      if (from is num &&
          to is num &&
          zoneStatus is String &&
          value >= from.toDouble() &&
          (value < to.toDouble() ||
              (value == maximum && to.toDouble() == maximum))) {
        status = zoneStatus;
        break;
      }
    }
  }
  return <ChartTableGaugeRow>[
    ChartTableGaugeRow(
      rowId: '${Uri.encodeComponent(series.id)}:0',
      reference: ChartTablePointReference(seriesId: series.id, pointIndex: 0),
      seriesId: series.id,
      metric: metricValue.trim(),
      valueRaw: value,
      valueDisplay: _displayNumber(value, formatter),
      minimumRaw: minimum,
      minimumDisplay: _displayNumber(minimum, formatter),
      maximumRaw: maximum,
      maximumDisplay: _displayNumber(maximum, formatter),
      progressRaw: progress,
      progressDisplay: valid
          ? '${(progress * 100).toStringAsFixed(2)}%'
          : 'No value',
      unit: unit,
      targetRaw: target,
      targetDisplay: target == null ? null : _displayNumber(target, formatter),
      status: status,
      isValid: valid,
    ),
  ];
}

const _candlestickPointExtensionKey = 'candlestick.ohlc.v1';

List<ChartTableCandlestickRow> _projectCandlestickRows(
  ChartSeriesDocument candlestick,
  List<ChartSeriesDocument> selected, {
  required String Function(double)? xFormatter,
  required Map<String, String Function(double)?> formattersBySeries,
  required Map<String, String?> unitsBySeries,
  required Map<String, bool> hiddenBySeries,
  required ChartViewState? viewState,
  required ChartTableOptions options,
}) {
  final candlePayload = candlestick.data;
  if (candlePayload is! InlineChartDataPayload) {
    throw UnsupportedError(
      'Candlestick table generation requires inline source data.',
    );
  }
  final overlayPointsByX = <String, Map<double, (int, ChartPointDocument)>>{};
  for (final overlay in selected.where((series) => series != candlestick)) {
    final payload = overlay.data;
    if (payload is! InlineChartDataPayload) {
      throw UnsupportedError(
        'Candlestick overlay tables require inline source data.',
      );
    }
    overlayPointsByX[overlay.id] = {
      for (final (index, point) in payload.points.indexed)
        point.x.asDouble: (index, point),
    };
  }

  final formatter = formattersBySeries[candlestick.id];
  final rows = <ChartTableCandlestickRow>[];
  for (final (pointIndex, point) in candlePayload.points.indexed) {
    final x = point.x.asDouble;
    if (!_inViewport(x, viewState, options)) continue;
    final extension = point.extensions[_candlestickPointExtensionKey];
    if (extension is! JsonObjectValue) {
      throw FormatException(
        'Candlestick point $pointIndex is missing its OHLC extension.',
      );
    }
    final open = _candlestickValue(extension, 'open', pointIndex);
    final high = _candlestickValue(extension, 'high', pointIndex);
    final low = _candlestickValue(extension, 'low', pointIndex);
    final close = _candlestickValue(extension, 'close', pointIndex);
    if (close != point.y.asDouble ||
        high < low ||
        high < open ||
        high < close ||
        low > open ||
        low > close) {
      throw FormatException('Candlestick point $pointIndex has invalid OHLC.');
    }
    final change = close - open;
    final changePercent = open == 0 ? null : (change / open) * 100;
    final overlays = <String, ChartTableWideCell>{};
    for (final overlay in selected.where((series) => series != candlestick)) {
      final match = overlayPointsByX[overlay.id]?[x];
      if (match == null) continue;
      final (overlayIndex, overlayPoint) = match;
      final value = overlayPoint.y.asDouble;
      overlays[overlay.id] = ChartTableWideCell(
        reference: ChartTablePointReference(
          seriesId: overlay.id,
          pointIndex: overlayIndex,
        ),
        yRaw: value,
        yDisplay: _displayNumber(value, formattersBySeries[overlay.id]),
        unit: unitsBySeries[overlay.id],
        timestamp: overlayPoint.timestamp,
        label: overlayPoint.label,
        metadata: options.includeMetadata ? overlayPoint.metadata : null,
        isValid: x.isFinite && value.isFinite,
      );
    }
    rows.add(
      ChartTableCandlestickRow(
        rowId: '${Uri.encodeComponent(candlestick.id)}:$pointIndex',
        reference: ChartTablePointReference(
          seriesId: candlestick.id,
          pointIndex: pointIndex,
        ),
        xRaw: x,
        xDisplay: _displayNumber(x, xFormatter),
        timestamp: point.timestamp,
        openRaw: open,
        openDisplay: _displayNumber(open, formatter),
        highRaw: high,
        highDisplay: _displayNumber(high, formatter),
        lowRaw: low,
        lowDisplay: _displayNumber(low, formatter),
        closeRaw: close,
        closeDisplay: _displayNumber(close, formatter),
        changeRaw: change,
        changeDisplay: _displayNumber(change, formatter),
        changePercentRaw: changePercent,
        changePercentDisplay: changePercent == null
            ? 'No value'
            : '${changePercent.toStringAsFixed(2)}%',
        unit: unitsBySeries[candlestick.id],
        label: point.label,
        isValid:
            x.isFinite &&
            open.isFinite &&
            high.isFinite &&
            low.isFinite &&
            close.isFinite,
        hiddenSeries: hiddenBySeries[candlestick.id] ?? false,
        overlayCells: overlays,
      ),
    );
  }
  return rows;
}

double _candlestickValue(
  JsonObjectValue extension,
  String key,
  int pointIndex,
) {
  final value = extension.values[key]?.toJson();
  if (value is! num || !value.isFinite) {
    throw FormatException(
      'Candlestick point $pointIndex $key must be a finite number.',
    );
  }
  return value.toDouble();
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

/// Consistent fallback for numeric table cells when the chart has not
/// supplied a domain-specific formatter.
String _plainNumber(double value) => value.toStringAsFixed(2);

String _xColumnLabel(ChartAxisDocument axis) {
  final label = axis.label?.trim();
  final unit = axis.unit?.trim();
  if (label != null && label.isNotEmpty) {
    return unit == null || unit.isEmpty ? label : '$label ($unit)';
  }
  return unit == null || unit.isEmpty ? 'X value' : unit;
}

({bool isGap, double? low, double? high}) _rangeAreaValues(
  ChartPointDocument point,
) {
  final extension = point.extensions['rangeArea.interval.v1'];
  if (extension is! JsonObjectValue) {
    throw const FormatException(
      'Range Area table points require a rangeArea.interval.v1 extension.',
    );
  }
  final isGap = extension.values['isGap']?.toJson();
  if (isGap is! bool) {
    throw const FormatException('Range Area point isGap must be boolean.');
  }
  if (isGap) return (isGap: true, low: null, high: null);

  final lowValue = extension.values['low']?.toJson();
  final highValue = extension.values['high']?.toJson();
  if (lowValue is! num || highValue is! num) {
    throw const FormatException(
      'Range Area low and high values must be numeric.',
    );
  }
  final low = lowValue.toDouble();
  final high = highValue.toDouble();
  if (!low.isFinite || !high.isFinite || low > high) {
    throw const FormatException(
      'Range Area table values require finite low <= high.',
    );
  }
  if (point.y.asDouble != (low + high) / 2) {
    throw const FormatException(
      'Range Area table midpoint must equal canonical y.',
    );
  }
  return (isGap: false, low: low, high: high);
}

Set<ChartTableAuxiliaryField> _auxiliaryFieldsForSeries(
  ChartSeriesDocument series,
) {
  if (series.type == 'rangeArea') {
    return const {
      ChartTableAuxiliaryField.rangeLow,
      ChartTableAuxiliaryField.rangeHigh,
      ChartTableAuxiliaryField.rangeSpan,
    };
  }
  if (series.type == 'heatmap') {
    return Set.unmodifiable({
      ChartTableAuxiliaryField.heatmapRowCoordinate,
      if (_heatmapSeriesHasExplicitBounds(series)) ...{
        ChartTableAuxiliaryField.heatmapXMinimum,
        ChartTableAuxiliaryField.heatmapXMaximum,
        ChartTableAuxiliaryField.heatmapYMinimum,
        ChartTableAuxiliaryField.heatmapYMaximum,
      },
    });
  }
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
  if (series.type == 'rangeArea') {
    final payload = series.data;
    if (payload is! InlineChartDataPayload ||
        pointIndex >= payload.points.length) {
      return const {};
    }
    final range = _rangeAreaValues(payload.points[pointIndex]);
    if (range.isGap) return const {};
    final low = range.low!;
    final high = range.high!;
    final span = high - low;
    return Map.unmodifiable({
      ChartTableAuxiliaryField.rangeLow: ChartTableAuxiliaryValue(
        raw: low,
        display: _displayNumber(low, formatter),
        isValid: low.isFinite,
      ),
      ChartTableAuxiliaryField.rangeHigh: ChartTableAuxiliaryValue(
        raw: high,
        display: _displayNumber(high, formatter),
        isValid: high.isFinite,
      ),
      ChartTableAuxiliaryField.rangeSpan: ChartTableAuxiliaryValue(
        raw: span,
        display: _displayNumber(span, formatter),
        isValid: span.isFinite && span >= 0,
      ),
    });
  }
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
      display: _displayNumber(raw, null),
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

typedef _HeatmapTableBounds = ({
  double xMinimum,
  double xMaximum,
  double yMinimum,
  double yMaximum,
});

({double? value, bool isMissing, _HeatmapTableBounds? bounds})
_heatmapCellValues(ChartPointDocument point) {
  final extension = point.extensions['heatmap.cell.v1'];
  if (extension is! JsonObjectValue) {
    throw const FormatException(
      'Heatmap table cells require heatmap.cell.v1 source values.',
    );
  }
  final rawMissing = extension.values['isMissing']?.toJson();
  if (rawMissing is! bool) {
    throw const FormatException(
      'Heatmap table cells require an explicit missing-state flag.',
    );
  }
  final bounds = _heatmapTableBounds(extension.values['bounds']);
  final rawValue = _chartNumber(extension.values['value']);
  if (rawMissing) {
    if (extension.values.containsKey('value')) {
      throw const FormatException(
        'Explicitly missing Heatmap table cells cannot carry a value.',
      );
    }
    return (value: null, isMissing: true, bounds: bounds);
  }
  if (rawValue == null || !rawValue.isFinite) {
    throw const FormatException(
      'Measured Heatmap table cells require a finite value.',
    );
  }
  return (value: rawValue, isMissing: false, bounds: bounds);
}

bool _heatmapSeriesHasExplicitBounds(ChartSeriesDocument series) {
  final payload = series.data;
  if (series.type != 'heatmap' || payload is! InlineChartDataPayload) {
    return false;
  }
  return payload.points.any((point) {
    final extension = point.extensions['heatmap.cell.v1'];
    return extension is JsonObjectValue &&
        extension.values['bounds'] is JsonObjectValue;
  });
}

_HeatmapTableBounds? _heatmapTableBounds(JsonValue? value) {
  if (value == null || value is JsonNullValue) return null;
  if (value is! JsonObjectValue) {
    throw const FormatException('Heatmap table cell bounds must be an object.');
  }
  final xMinimum = _chartNumber(value.values['xMinimum']);
  final xMaximum = _chartNumber(value.values['xMaximum']);
  final yMinimum = _chartNumber(value.values['yMinimum']);
  final yMaximum = _chartNumber(value.values['yMaximum']);
  if (xMinimum == null ||
      xMaximum == null ||
      yMinimum == null ||
      yMaximum == null ||
      !xMinimum.isFinite ||
      !xMaximum.isFinite ||
      !yMinimum.isFinite ||
      !yMaximum.isFinite ||
      xMinimum >= xMaximum ||
      yMinimum >= yMaximum) {
    throw const FormatException(
      'Heatmap table cell bounds require finite positive extents.',
    );
  }
  return (
    xMinimum: xMinimum,
    xMaximum: xMaximum,
    yMinimum: yMinimum,
    yMaximum: yMaximum,
  );
}

String _heatmapColumnId(double x) {
  final encoded = canonicalJsonEncode(
    ChartNumberDocument.fromDouble(x).toJson(),
  );
  return 'heatmap-x:${Uri.encodeComponent(encoded)}';
}

List<ChartTableSeriesColumn> _heatmapMatrixColumns(
  List<ChartTableLongRow> longRows, {
  required String? unit,
  required bool hidden,
}) {
  final byX = <double, String>{};
  for (final row in longRows) {
    byX.putIfAbsent(row.xRaw, () => row.xDisplay);
  }
  final coordinates = byX.keys.toList()..sort();
  return [
    for (final x in coordinates)
      ChartTableSeriesColumn(
        seriesId: _heatmapColumnId(x),
        seriesName: byX[x]!,
        unit: unit,
        hidden: hidden,
      ),
  ];
}

List<ChartTableWideRow> _pivotHeatmapMatrix(
  List<ChartTableLongRow> longRows,
  List<ChartTableSeriesColumn> columns,
) {
  final rows = <double, _MutableWideRow>{};
  for (final row in longRows) {
    final rowCoordinate =
        row.auxiliaryValues[ChartTableAuxiliaryField.heatmapRowCoordinate];
    if (rowCoordinate == null) {
      throw const FormatException(
        'Heatmap matrix rows require their canonical Y coordinate.',
      );
    }
    final wide = rows.putIfAbsent(
      rowCoordinate.raw,
      () => _MutableWideRow(
        rowId: 'heatmap-y:${Uri.encodeComponent(rowCoordinate.display)}',
        xRaw: rowCoordinate.raw,
        xDisplay: rowCoordinate.display,
      ),
    );
    wide.cells[_heatmapColumnId(row.xRaw)] = ChartTableWideCell(
      reference: row.reference,
      yRaw: row.yRaw,
      yDisplay: row.yDisplay,
      unit: row.unit,
      timestamp: row.timestamp,
      label: row.label,
      categoryValue: row.categoryValue,
      isValid: row.isValid,
      metadata: row.metadata,
    );
  }
  final knownIds = columns.map((column) => column.seriesId).toSet();
  final ordered = rows.values.toList()
    ..sort((left, right) => left.xRaw.compareTo(right.xRaw));
  return [
    for (final row in ordered)
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
      categoryValue: row.categoryValue,
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

String? _categoryLabelForSeries(ChartSeriesDocument series) {
  final encoding = series.style?.values['categoryEncoding'];
  if (encoding is! JsonObjectValue) return null;
  final label = encoding.values['label']?.toJson();
  return label is String && label.isNotEmpty ? label : 'Category';
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
