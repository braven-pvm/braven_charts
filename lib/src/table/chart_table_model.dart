import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_data_payload.dart';
import '../artifacts/chart_document.dart';
import '../artifacts/chart_runtime_bindings.dart';
import '../artifacts/chart_view_state.dart';
import '../artifacts/json_value.dart';
import 'chart_table_options.dart';

@immutable
class ChartTablePointReference {
  const ChartTablePointReference({
    required this.seriesId,
    required this.pointIndex,
  });

  final String seriesId;
  final int pointIndex;
}

@immutable
class ChartTableSeriesColumn {
  const ChartTableSeriesColumn({
    required this.seriesId,
    required this.seriesName,
    required this.hidden,
    this.unit,
  });

  final String seriesId;
  final String seriesName;
  final String? unit;
  final bool hidden;
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
    required this.options,
    required Iterable<ChartTableSeriesColumn> series,
    required Iterable<ChartTableLongRow> longRows,
    required Iterable<ChartTableWideRow> wideRows,
    required Iterable<ChartArtifactWarning> warnings,
  }) : series = List.unmodifiable(series),
       longRows = List.unmodifiable(longRows),
       wideRows = List.unmodifiable(wideRows),
       warnings = List.unmodifiable(warnings);

  factory ChartTableModel.fromDocument(
    ChartDocument document, {
    ChartViewState? viewState,
    ChartTableOptions options = const ChartTableOptions(),
  }) {
    final warnings = <ChartArtifactWarning>[];
    final hiddenIds = viewState?.hiddenSeriesIds ?? const <String>{};
    final selected = _selectSeries(document, viewState, options);
    final xFormatter = _resolveFormatter(
      document.xAxis.formatter,
      options.formatters,
      warnings,
      r'$.document.xAxis.formatter',
    );
    final axesById = {for (final axis in document.axes) axis.id: axis};
    final seriesColumns = <ChartTableSeriesColumn>[];
    final longRows = <ChartTableLongRow>[];

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
        ),
      );
      final payload = series.data;
      if (payload is! InlinePointPayload) {
        throw UnsupportedError(
          'Table generation does not support ${payload.storage} payloads.',
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
            xDisplay: _displayNumber(x, xFormatter),
            yRaw: y,
            yDisplay: _displayNumber(y, yFormatter),
            unit: unit,
            timestamp: point.timestamp,
            label: point.label,
            isValid: x.isFinite && y.isFinite,
            hiddenSeries: hidden,
            metadata: options.includeMetadata ? point.metadata : null,
          ),
        );
      }
    }

    return ChartTableModel._(
      documentId: document.documentId,
      documentRevision: document.revision,
      xColumnLabel: _xColumnLabel(document.xAxis),
      options: options,
      series: seriesColumns,
      longRows: longRows,
      wideRows: options.rowLayout == ChartTableRowLayout.wide
          ? _pivotExactX(longRows, seriesColumns)
          : const [],
      warnings: warnings,
    );
  }

  final String documentId;
  final int documentRevision;
  final String xColumnLabel;
  final ChartTableOptions options;
  final List<ChartTableSeriesColumn> series;
  final List<ChartTableLongRow> longRows;
  final List<ChartTableWideRow> wideRows;
  final List<ChartArtifactWarning> warnings;

  int get rowCount => options.rowLayout == ChartTableRowLayout.long
      ? longRows.length
      : wideRows.length;

  bool get isEmpty => rowCount == 0;

  String get scopeLabel => switch (options.dataScope) {
    ChartTableDataScope.allSeries => 'All series',
    ChartTableDataScope.visibleSeries => 'Visible series',
    ChartTableDataScope.selectedSeries => 'Selected series',
    ChartTableDataScope.specifiedSeries => 'Specified series',
  };
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
