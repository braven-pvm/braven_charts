import 'package:flutter/foundation.dart';

import 'chart_comparison_model.dart';

/// One comparison export column with explicit source/derived provenance.
@immutable
class ChartComparisonExportColumn {
  const ChartComparisonExportColumn({
    required this.id,
    required this.label,
    required this.isDerived,
  });

  final String id;
  final String label;
  final bool isDerived;
}

/// One export row aligned with [ChartComparisonExport.columns].
@immutable
class ChartComparisonExportRow {
  ChartComparisonExportRow({required Iterable<Object?> values})
    : values = List.unmodifiable(values);

  final List<Object?> values;
}

/// Source-preserving comparison export with derived-column metadata.
@immutable
class ChartComparisonExport {
  ChartComparisonExport({
    required Iterable<ChartComparisonExportColumn> columns,
    required Iterable<ChartComparisonExportRow> rows,
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(rows) {
    for (final row in this.rows) {
      if (row.values.length != this.columns.length) {
        throw ArgumentError('Comparison export rows must align with columns.');
      }
    }
  }

  final List<ChartComparisonExportColumn> columns;
  final List<ChartComparisonExportRow> rows;

  /// RFC-style CSV retaining raw source values and labelled derived columns.
  String get csv => <String>[
    columns.map((column) => _escapeCsv(column.label)).join(','),
    for (final row in rows) row.values.map(_escapeCsv).join(','),
  ].join('\r\n');
}

/// Builds a rectangular export without hiding source values behind deltas.
abstract final class ChartComparisonExporter {
  static ChartComparisonExport export(ChartComparisonModel model) {
    final alignmentXDerived =
        model.options.comparisonXUnit != null &&
        model.options.xUnitConversionsByInputId.isNotEmpty;
    final columns = <ChartComparisonExportColumn>[
      const ChartComparisonExportColumn(
        id: 'semanticKey',
        label: 'Semantic key',
        isDerived: false,
      ),
      ChartComparisonExportColumn(
        id: 'alignmentX',
        label: alignmentXDerived ? 'Alignment X [derived]' : 'Alignment X',
        isDerived: alignmentXDerived,
      ),
      const ChartComparisonExportColumn(
        id: 'alignmentTimestamp',
        label: 'Alignment timestamp',
        isDerived: false,
      ),
      const ChartComparisonExportColumn(
        id: 'isAligned',
        label: 'Aligned',
        isDerived: false,
      ),
    ];
    for (final input in model.inputs) {
      final prefix = input.inputId;
      columns.addAll([
        ChartComparisonExportColumn(
          id: '$prefix.seriesId',
          label: '${input.label} · Series ID',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.rawX',
          label: '${input.label} · Raw X',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.xDisplay',
          label: '${input.label} · Display X',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.rawY',
          label: '${input.label} · Raw Y',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.yDisplay',
          label: '${input.label} · Display Y',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.sourceUnit',
          label: '${input.label} · Source unit',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.missing',
          label: '${input.label} · Missing',
          isDerived: false,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.comparisonValue',
          label: '${input.label} · Comparison value [derived]',
          isDerived: true,
        ),
        ChartComparisonExportColumn(
          id: '$prefix.comparisonUnit',
          label: '${input.label} · Comparison unit [derived]',
          isDerived: true,
        ),
      ]);
      if (model.options.baselineInputId != null) {
        columns.addAll([
          ChartComparisonExportColumn(
            id: '$prefix.absoluteDelta',
            label: '${input.label} · Absolute delta [derived]',
            isDerived: true,
          ),
          ChartComparisonExportColumn(
            id: '$prefix.percentageDelta',
            label: '${input.label} · Percentage delta [derived]',
            isDerived: true,
          ),
          ChartComparisonExportColumn(
            id: '$prefix.deltaStatus',
            label: '${input.label} · Delta status [derived]',
            isDerived: true,
          ),
        ]);
      }
    }

    final rows = <ChartComparisonExportRow>[];
    for (final row in model.rows) {
      final values = <Object?>[
        row.semanticKey,
        row.alignmentX,
        row.alignmentTimestamp?.toUtc().toIso8601String(),
        row.isAligned,
      ];
      for (final input in model.inputs) {
        final value = row.valuesByInputId[input.inputId]!;
        values.addAll([
          value.sourceSeriesId,
          value.rawX,
          value.xDisplay,
          value.rawY,
          value.yDisplay,
          value.sourceUnit,
          value.isMissing,
          value.comparisonValue,
          value.comparisonUnit,
        ]);
        if (model.options.baselineInputId != null) {
          final delta = row.deltasByInputId[input.inputId]!;
          values.addAll([delta.absolute, delta.percentage, delta.status.name]);
        }
      }
      rows.add(ChartComparisonExportRow(values: values));
    }
    return ChartComparisonExport(columns: columns, rows: rows);
  }
}

String _escapeCsv(Object? value) {
  if (value == null) return '';
  final text = value.toString();
  if (!text.contains(RegExp('[,"\r\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}
