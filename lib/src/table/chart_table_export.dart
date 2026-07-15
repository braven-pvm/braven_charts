import 'package:flutter/foundation.dart';

import 'chart_table_model.dart';
import 'chart_table_options.dart';

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
  }) {
    final rows = model.options.rowLayout == ChartTableRowLayout.wide
        ? [
            for (final (index, row) in wideRows.indexed)
              wideRow(model, row, index),
          ]
        : [
            for (final (index, row) in longRows.indexed)
              longRow(model, row, index),
          ];
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
      for (final column in model.series) row.cells[column.seriesId]?.yRaw,
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.xDisplay,
      for (final column in model.series)
        row.cells[column.seriesId]?.yDisplay ?? 'No value',
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
      row.xRaw,
      row.yRaw,
      row.unit,
      row.label,
      row.isValid ? 'Valid' : 'No value',
    ],
    displayValues: [
      '${displayIndex + 1}',
      row.seriesName,
      row.xDisplay,
      row.yDisplay,
      row.unit ?? 'No unit',
      row.label ?? 'No label',
      row.isValid ? 'Valid' : 'No value',
    ],
    references: [row.reference],
  );

  static List<String> headers(ChartTableModel model) =>
      model.options.rowLayout == ChartTableRowLayout.wide
      ? [
          '#',
          model.xColumnLabel,
          for (final column in model.series)
            column.unit == null
                ? column.seriesName
                : '${column.seriesName} (${column.unit})',
        ]
      : [
          '#',
          'Series',
          model.xColumnLabel,
          'Y value',
          'Unit',
          'Label',
          'Status',
        ];
}

String _escapeCsvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(RegExp('[,"\\r\\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

String _escapeTsvCell(String value) =>
    value.replaceAll('\t', ' ').replaceAll(RegExp(r'\r\n|\r|\n'), ' ');
