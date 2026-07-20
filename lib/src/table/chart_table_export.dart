import 'package:flutter/foundation.dart';

import 'chart_table_model.dart';

/// One displayed table row prepared for host copy/export behavior.
///
/// [rawValues] preserve sortable/exportable chart values. [displayValues]
/// preserve the formatter-derived strings visible to the user.
@immutable
class ChartTableRowExport {
  ChartTableRowExport({
    required this.rowId,
    required Iterable<String> headers,
    required Iterable<Object?> rawValues,
    required Iterable<String> displayValues,
    required Iterable<ChartTablePointReference> references,
  }) : headers = List.unmodifiable(headers),
       rawValues = List.unmodifiable(rawValues),
       displayValues = List.unmodifiable(displayValues),
       references = List.unmodifiable(references) {
    if (this.headers.length != this.rawValues.length ||
        this.headers.length != this.displayValues.length) {
      throw ArgumentError(
        'Row export headers, raw values, and display values must align.',
      );
    }
  }

  final String rowId;
  final List<String> headers;
  final List<Object?> rawValues;
  final List<String> displayValues;
  final List<ChartTablePointReference> references;

  /// Tab-separated formatted text suitable for a spreadsheet clipboard.
  String get tabSeparatedText => displayValues.map(_escapeTsvCell).join('\t');
}

/// Raw-value CSV and display-value TSV prepared by [ChartTableExporter].
///
/// [ChartDataTable] provides native clipboard delivery and automatic web CSV
/// download. Hosts can still take this projection over for platform file,
/// share-sheet, object-storage, permission, or audit workflows.
@immutable
class ChartTableCsvExport {
  ChartTableCsvExport({
    required Iterable<String> headers,
    required Iterable<ChartTableRowExport> rows,
  }) : headers = List.unmodifiable(headers),
       rows = List.unmodifiable(rows) {
    for (final row in this.rows) {
      if (!listEquals(row.headers, this.headers)) {
        throw ArgumentError('Every CSV row must use the export headers.');
      }
    }
  }

  final List<String> headers;
  final List<ChartTableRowExport> rows;

  /// Display-formatted TSV suitable for pasting into a spreadsheet.
  ///
  /// CSV exports retain raw values; clipboard copies intentionally use the
  /// same formatted values shown in the table.
  String get tabSeparatedText => <String>[
    headers.map(_escapeTsvCell).join('\t'),
    for (final row in rows) row.tabSeparatedText,
  ].join('\r\n');

  String get csv => <String>[
    headers.map(_escapeCsvCell).join(','),
    for (final row in rows) row.rawValues.map(_escapeCsvCell).join(','),
  ].join('\r\n');
}

/// Builds copy and CSV projections without coupling delivery to Flutter IO.
abstract final class ChartTableExporter {
  static ChartTableCsvExport csvForDisplayedRows(
    ChartTableModel model, {
    Iterable<ChartTableLongRow> longRows = const [],
    Iterable<ChartTableWideRow> wideRows = const [],
    Iterable<ChartTablePieRow> pieRows = const [],
    Iterable<ChartTablePolarRow> polarRows = const [],
    Iterable<ChartTableCandlestickRow> candlestickRows = const [],
  }) {
    final rows = switch (model.projectionKind) {
      ChartTableProjectionKind.cartesianWide => [
        for (final (index, row) in wideRows.indexed) wideRow(model, row, index),
      ],
      ChartTableProjectionKind.cartesianLong => [
        for (final (index, row) in longRows.indexed) longRow(model, row, index),
      ],
      ChartTableProjectionKind.pie => [
        for (final (index, row) in pieRows.indexed) pieRow(model, row, index),
      ],
      ChartTableProjectionKind.polar => [
        for (final (index, row) in polarRows.indexed)
          polarRow(model, row, index),
      ],
      ChartTableProjectionKind.candlestick => [
        for (final (index, row) in candlestickRows.indexed)
          candlestickRow(model, row, index),
      ],
    };
    return ChartTableCsvExport(headers: headers(model), rows: rows);
  }

  static ChartTableRowExport wideRow(
    ChartTableModel model,
    ChartTableWideRow row,
    int displayIndex,
  ) => ChartTableRowExport(
    rowId: row.rowId,
    headers: headers(model),
    rawValues: [
      displayIndex + 1,
      row.xRaw,
      for (final column in model.series) ...[
        row.cells[column.seriesId]?.yRaw,
        if (column.categoryLabel != null)
          row.cells[column.seriesId]?.categoryValue,
        for (final field in _orderedAuxiliaryFields(column.auxiliaryFields))
          row.cells[column.seriesId]?.auxiliaryValues[field]?.raw,
      ],
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.xDisplay,
      for (final column in model.series) ...[
        row.cells[column.seriesId]?.yDisplay ?? 'No value',
        if (column.categoryLabel != null)
          row.cells[column.seriesId]?.categoryValue ?? 'No value',
        for (final field in _orderedAuxiliaryFields(column.auxiliaryFields))
          row.cells[column.seriesId]?.auxiliaryValues[field]?.display ??
              'No value',
      ],
    ],
    references: [
      for (final column in model.series)
        if (row.cells[column.seriesId] case final cell?) cell.reference,
    ],
  );

  static ChartTableRowExport longRow(
    ChartTableModel model,
    ChartTableLongRow row,
    int displayIndex,
  ) => ChartTableRowExport(
    rowId: row.rowId,
    headers: headers(model),
    rawValues: [
      displayIndex + 1,
      row.seriesName,
      if (model.hasCategoryValues) row.categoryValue,
      row.xRaw,
      row.yRaw,
      for (final field in _orderedAuxiliaryFields(model.auxiliaryFields))
        row.auxiliaryValues[field]?.raw,
      row.unit,
      row.label,
      row.isValid ? 'Valid' : 'No value',
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.seriesName,
      if (model.hasCategoryValues) row.categoryValue ?? 'No value',
      row.xDisplay,
      row.yDisplay,
      for (final field in _orderedAuxiliaryFields(model.auxiliaryFields))
        row.auxiliaryValues[field]?.display ?? 'No value',
      row.unit ?? 'No unit',
      row.label ?? 'No label',
      row.isValid ? 'Valid' : 'No value',
    ],
    references: [row.reference],
  );

  static ChartTableRowExport pieRow(
    ChartTableModel model,
    ChartTablePieRow row,
    int displayIndex,
  ) => ChartTableRowExport(
    rowId: row.rowId,
    headers: headers(model),
    rawValues: [
      displayIndex + 1,
      if (model.hasMultipleRadialSeries) ...[row.seriesName, row.seriesId],
      row.category,
      row.valueRaw,
      if (model.hasPieRadiusValues) row.radiusRaw,
      row.shareRaw,
    ],
    displayValues: [
      '${displayIndex + 1}',
      if (model.hasMultipleRadialSeries) ...[row.seriesName, row.seriesId],
      row.category,
      row.valueDisplay,
      if (model.hasPieRadiusValues) row.radiusDisplay ?? 'No value',
      row.shareDisplay,
    ],
    references: [row.reference],
  );

  static ChartTableRowExport polarRow(
    ChartTableModel model,
    ChartTablePolarRow row,
    int displayIndex,
  ) => ChartTableRowExport(
    rowId: row.rowId,
    headers: headers(model),
    rawValues: [
      displayIndex + 1,
      row.category,
      row.seriesName,
      row.valueRaw,
      if (model.hasPolarTargets) row.targetRaw,
      if (model.hasPolarIntervals) ...[
        row.intervalLowerRaw,
        row.intervalUpperRaw,
      ],
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.category,
      row.seriesName,
      row.valueDisplay,
      if (model.hasPolarTargets) row.targetDisplay ?? 'No target',
      if (model.hasPolarIntervals) ...[
        row.intervalLowerDisplay ?? 'No lower bound',
        row.intervalUpperDisplay ?? 'No upper bound',
      ],
    ],
    references: [row.reference],
  );

  static ChartTableRowExport candlestickRow(
    ChartTableModel model,
    ChartTableCandlestickRow row,
    int displayIndex,
  ) => ChartTableRowExport(
    rowId: row.rowId,
    headers: headers(model),
    rawValues: [
      displayIndex + 1,
      row.timestamp?.toUtc().toIso8601String(),
      row.xRaw,
      row.openRaw,
      row.highRaw,
      row.lowRaw,
      row.closeRaw,
      row.changeRaw,
      row.changePercentRaw,
      row.unit,
      row.label,
      for (final column in model.series.where(
        (column) => column.seriesId != row.reference.seriesId,
      ))
        row.overlayCells[column.seriesId]?.yRaw,
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.timestamp?.toUtc().toIso8601String() ?? 'No timestamp',
      row.xDisplay,
      row.openDisplay,
      row.highDisplay,
      row.lowDisplay,
      row.closeDisplay,
      row.changeDisplay,
      row.changePercentDisplay,
      row.unit ?? 'No unit',
      row.label ?? 'No label',
      for (final column in model.series.where(
        (column) => column.seriesId != row.reference.seriesId,
      ))
        row.overlayCells[column.seriesId]?.yDisplay ?? 'No value',
    ],
    references: [
      row.reference,
      ...row.overlayCells.values.map((e) => e.reference),
    ],
  );

  static List<String> headers(ChartTableModel model) =>
      switch (model.projectionKind) {
        ChartTableProjectionKind.cartesianWide => [
          '#',
          model.xColumnLabel,
          for (final column in model.series) ...[
            column.unit == null
                ? column.seriesName
                : '${column.seriesName} (${column.unit})',
            if (column.categoryLabel != null)
              '${column.seriesName} ${column.categoryLabel!.toLowerCase()}',
            for (final field in _orderedAuxiliaryFields(column.auxiliaryFields))
              (field.unitOverride ?? column.unit) == null
                  ? '${column.seriesName} ${field.label.toLowerCase()}'
                  : '${column.seriesName} ${field.label.toLowerCase()} '
                        '(${field.unitOverride ?? column.unit})',
          ],
        ],
        ChartTableProjectionKind.cartesianLong => [
          '#',
          'Series',
          if (model.hasCategoryValues) 'Category',
          model.xColumnLabel,
          'Y value',
          for (final field in _orderedAuxiliaryFields(model.auxiliaryFields))
            field.unitOverride == null
                ? field.label
                : '${field.label} (${field.unitOverride})',
          'Unit',
          'Label',
          'Status',
        ],
        ChartTableProjectionKind.pie => [
          '#',
          if (model.hasMultipleRadialSeries) ...['Ring', 'Series ID'],
          'Category',
          model.commonRadialUnit == null
              ? 'Value'
              : 'Value (${model.commonRadialUnit})',
          ?model.pieRadiusColumnLabel,
          'Share',
        ],
        ChartTableProjectionKind.polar => [
          '#',
          'Category',
          'Series',
          model.commonRadialUnit == null
              ? 'Value'
              : 'Value (${model.commonRadialUnit})',
          if (model.hasPolarTargets)
            model.commonRadialUnit == null
                ? 'Target'
                : 'Target (${model.commonRadialUnit})',
          if (model.hasPolarIntervals) ...[
            model.commonRadialUnit == null
                ? 'Lower'
                : 'Lower (${model.commonRadialUnit})',
            model.commonRadialUnit == null
                ? 'Upper'
                : 'Upper (${model.commonRadialUnit})',
          ],
        ],
        ChartTableProjectionKind.candlestick => [
          '#',
          'Time',
          model.xColumnLabel,
          'Open',
          'High',
          'Low',
          'Close',
          'Change',
          'Change %',
          'Unit',
          'Label',
          for (final column in model.series.skip(1))
            column.unit == null
                ? column.seriesName
                : '${column.seriesName} (${column.unit})',
        ],
      };
}

Iterable<ChartTableAuxiliaryField> _orderedAuxiliaryFields(
  Set<ChartTableAuxiliaryField> fields,
) => ChartTableAuxiliaryField.values.where(fields.contains);

String _escapeCsvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(RegExp('[,"\\r\\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

String _escapeTsvCell(String value) =>
    value.replaceAll('\t', ' ').replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
