import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../artifacts/chart_view_state.dart';
import 'chart_table_controller.dart';
import 'chart_table_csv_download.dart';
import 'chart_data_table_theme.dart';
import 'chart_table_export.dart';
import 'chart_table_model.dart';

/// Reports every chart point represented by one visible table row.
///
/// Long-form rows contain one reference. Wide-form rows contain one reference
/// per populated series cell at the row's exact X value.
typedef ChartTableRowCallback = void Function(List<ChartPointRef> points);

/// Reports the row currently under the pointer, or null when it exits.
typedef ChartTableRowHoverCallback = void Function(List<ChartPointRef>? points);

/// Accessible, horizontally scrollable, row-virtualized chart data table.
///
/// Supply a [ChartTableModel] created from the same [ChartDocument] that feeds
/// the chart. The widget uses the model's row layout, keeps raw values for
/// export, and derives unspecified colors and typography from the active
/// [ChartDataTableTheme] and the ambient Flutter theme.
class ChartDataTable extends StatefulWidget {
  static const defaultClipboardRowLimit = 1000;
  static const defaultClipboardCharacterLimit = 1000000;

  const ChartDataTable({
    super.key,
    this.model,
    this.controller,
    this.isLoading = false,
    this.errorMessage,
    this.onRowFocused,
    this.onRowFocusCleared,
    this.onRowHoverChanged,
    this.onRowActivated,
    this.selectedPointRefs = const <ChartPointRef>{},
    this.onCopyRow,
    this.onCopyDataset,
    this.onExportCsv,
    this.showCopyRowAction = true,
    this.showCopyDatasetAction = true,
    this.showExportCsvAction = true,
    this.clipboardRowLimit = defaultClipboardRowLimit,
    this.clipboardCharacterLimit = defaultClipboardCharacterLimit,
    this.csvFileName,
    this.emptyMessage = 'No chart data',
    this.theme,
  }) : assert(
         model != null || isLoading || errorMessage != null,
         'Provide a model, loading state, or error message.',
       ),
       assert(clipboardRowLimit > 0, 'clipboardRowLimit must be positive.'),
       assert(
         clipboardCharacterLimit > 0,
         'clipboardCharacterLimit must be positive.',
       );

  final ChartTableModel? model;
  final ChartTableController? controller;
  final bool isLoading;
  final String? errorMessage;

  /// Called with every point represented by a row when it gains keyboard focus.
  final ChartTableRowCallback? onRowFocused;

  /// Called when keyboard focus leaves a focused row.
  final VoidCallback? onRowFocusCleared;

  /// Reports pointer entry with row refs and pointer exit with null.
  final ChartTableRowHoverCallback? onRowHoverChanged;

  /// Called by row click or Enter with every point represented by that row.
  ///
  /// When supplied, activation takes precedence over drag-selecting cell text;
  /// use the table's row or dataset copy actions for clipboard workflows.
  final ChartTableRowCallback? onRowActivated;

  /// Durable chart-point selection mirrored into visible table rows.
  ///
  /// A long row is selected when its point is present. A wide exact-X row is
  /// selected only when every populated series point represented by that row
  /// is present, so a partial point selection never implies whole-row state.
  final Set<ChartPointRef> selectedPointRefs;

  /// Overrides the default clipboard delivery for one requested visible row.
  ///
  /// The row action remains native to the table. When this callback is null,
  /// the table copies [ChartTableRowExport.tabSeparatedText] itself.
  final ValueChanged<ChartTableRowExport>? onCopyRow;

  /// Overrides the default clipboard delivery for the displayed dataset.
  ///
  /// The table enforces [clipboardRowLimit] and [clipboardCharacterLimit]
  /// before invoking this callback.
  final ValueChanged<ChartTableCsvExport>? onCopyDataset;

  /// Overrides default CSV delivery in the current scope and sort order.
  ///
  /// Without a callback, web builds download the CSV directly. Other
  /// platforms keep the action visible and explain that a host delivery
  /// callback is required.
  final ValueChanged<ChartTableCsvExport>? onExportCsv;
  final bool showCopyRowAction;
  final bool showCopyDatasetAction;
  final bool showExportCsvAction;

  /// Maximum displayed rows allowed in one whole-dataset clipboard copy.
  final int clipboardRowLimit;

  /// Maximum TSV characters allowed in one whole-dataset clipboard copy.
  final int clipboardCharacterLimit;

  /// Optional CSV file name. Defaults to the sanitized document ID.
  final String? csvFileName;
  final String emptyMessage;

  /// Per-table visual overrides.
  ///
  /// When omitted, the widget uses the nearest [ChartDataTableTheme] extension
  /// and then derives any unspecified colors and text styles from the ambient
  /// Flutter theme.
  final ChartDataTableTheme? theme;

  @override
  State<ChartDataTable> createState() => _ChartDataTableState();
}

class _ChartDataTableState extends State<ChartDataTable> {
  late ChartTableController _controller;
  late bool _ownsController;
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final _rowFocusNodes = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(ChartDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleControllerChanged);
      if (_ownsController) _controller.dispose();
      _attachController(widget.controller);
    }
  }

  void _attachController(ChartTableController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? ChartTableController();
    _controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() => setState(() {});

  Future<void> _copyDataset(ChartTableCsvExport export) async {
    if (export.rows.length > widget.clipboardRowLimit) {
      _showMessage(
        'This table has ${export.rows.length} rows and is too large to copy. '
        'Use Export CSV instead.',
      );
      return;
    }
    final text = export.tabSeparatedText;
    if (text.length > widget.clipboardCharacterLimit) {
      _showMessage(
        'This table is too large to copy safely. Use Export CSV instead.',
      );
      return;
    }
    final handler = widget.onCopyDataset;
    if (handler != null) {
      handler(export);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showMessage('Copied ${export.rows.length} rows to the clipboard.');
  }

  Future<void> _copyRow(ChartTableRowExport row, int displayIndex) async {
    final handler = widget.onCopyRow;
    if (handler != null) {
      handler(row);
      return;
    }
    await Clipboard.setData(ClipboardData(text: row.tabSeparatedText));
    if (!mounted) return;
    _showMessage('Copied row ${displayIndex + 1} to the clipboard.');
  }

  Future<void> _exportCsv(
    ChartTableModel model,
    ChartTableCsvExport export,
  ) async {
    final handler = widget.onExportCsv;
    if (handler != null) {
      handler(export);
      return;
    }
    final fileName = _resolvedCsvFileName(model);
    final downloaded = await downloadChartTableCsv(
      csv: export.csv,
      fileName: fileName,
    );
    if (!mounted) return;
    if (downloaded) {
      _showMessage('Exported ${export.rows.length} rows to $fileName.');
    } else {
      _showMessage(
        'Automatic CSV download is unavailable on this platform. '
        'Provide onExportCsv to save the file.',
      );
    }
  }

  String _resolvedCsvFileName(ChartTableModel model) {
    var fileName = widget.csvFileName?.trim();
    if (fileName == null || fileName.isEmpty) fileName = model.documentId;
    fileName = fileName.replaceAll(RegExp(r'''[<>:"/\\|?*\x00-\x1F]'''), '-');
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      fileName = 'chart-data';
    }
    return fileName.toLowerCase().endsWith('.csv') ? fileName : '$fileName.csv';
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    for (final node in _rowFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const _TableLoadingState();
    if (widget.errorMessage != null) {
      return _TableMessageState(
        icon: Icons.error_outline,
        title: 'Chart data unavailable',
        message: widget.errorMessage!,
        isError: true,
      );
    }
    final model = widget.model;
    if (model == null || model.isEmpty) {
      return _TableMessageState(
        icon: Icons.table_rows_outlined,
        title: widget.emptyMessage,
        message: 'Change the active series or viewport scope to show rows.',
      );
    }
    final longRows =
        model.projectionKind == ChartTableProjectionKind.cartesianLong
        ? _sortedLongRows(model)
        : const <ChartTableLongRow>[];
    final wideRows =
        model.projectionKind == ChartTableProjectionKind.cartesianWide
        ? _sortedWideRows(model)
        : const <ChartTableWideRow>[];
    final pieRows = model.projectionKind == ChartTableProjectionKind.pie
        ? _sortedPieRows(model)
        : const <ChartTablePieRow>[];
    final tableTheme = _ResolvedTableTheme.from(
      context,
      widget.theme ?? Theme.of(context).extension<ChartDataTableTheme>(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 960.0;
        final contentWidth = math.max(
          viewportWidth,
          switch (model.projectionKind) {
            ChartTableProjectionKind.cartesianLong =>
              tableTheme.rowNumberWidth +
                  192 +
                  tableTheme.xColumnWidth +
                  tableTheme.seriesColumnWidth +
                  88 +
                  144 +
                  96 +
                  (widget.showCopyRowAction ? 44 : 0),
            ChartTableProjectionKind.cartesianWide =>
              tableTheme.rowNumberWidth +
                  tableTheme.xColumnWidth +
                  model.series.length * tableTheme.seriesColumnWidth +
                  (widget.showCopyRowAction ? 44 : 0),
            ChartTableProjectionKind.pie =>
              tableTheme.rowNumberWidth +
                  192 +
                  tableTheme.seriesColumnWidth *
                      (model.hasPieRadiusValues ? 3 : 2) +
                  (widget.showCopyRowAction ? 44 : 0),
          },
        );
        ChartTableCsvExport buildDatasetExport() =>
            ChartTableExporter.csvForDisplayedRows(
              model,
              longRows: longRows,
              wideRows: wideRows,
              pieRows: pieRows,
            );
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TableSummary(
                model: model,
                onCopyDataset: !widget.showCopyDatasetAction
                    ? null
                    : () => _copyDataset(buildDatasetExport()),
                onExportCsv: !widget.showExportCsvAction
                    ? null
                    : () => _exportCsv(model, buildDatasetExport()),
                theme: tableTheme,
              ),
              if (model.warnings.isNotEmpty)
                _TableWarningBanner(count: model.warnings.length),
              Expanded(
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          _buildHeader(model, tableTheme),
                          Expanded(
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: _TableSelectionBoundary(
                                enableSelection: widget.onRowActivated == null,
                                child: ListView.builder(
                                  controller: _verticalController,
                                  itemExtent: tableTheme.rowHeight,
                                  itemCount: model.rowCount,
                                  itemBuilder: (context, index) => _buildRow(
                                    model,
                                    index,
                                    longRows: longRows,
                                    wideRows: wideRows,
                                    pieRows: pieRows,
                                    theme: tableTheme,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ChartTableModel model, _ResolvedTableTheme tableTheme) {
    if (model.projectionKind == ChartTableProjectionKind.pie) {
      final unit = model.series.single.unit;
      return _TableHeader(
        theme: tableTheme,
        children: [
          if (widget.showCopyRowAction)
            _StaticHeader(
              key: const ValueKey('chart-table-header-row-actions'),
              label: '',
              semanticsLabel: 'Row actions',
              width: 44,
              theme: tableTheme,
            ),
          _StaticHeader(
            key: const ValueKey('chart-table-header-index'),
            label: '#',
            width: tableTheme.rowNumberWidth,
            theme: tableTheme,
            numeric: true,
          ),
          _SortHeader(
            key: const ValueKey('chart-table-header-category'),
            label: 'Category',
            columnId: 'category',
            width: 192,
            controller: _controller,
            theme: tableTheme,
          ),
          _SortHeader(
            key: const ValueKey('chart-table-header-value'),
            label: unit == null ? 'Value' : 'Value ($unit)',
            columnId: 'value',
            width: tableTheme.seriesColumnWidth,
            controller: _controller,
            theme: tableTheme,
            numeric: true,
          ),
          if (model.pieRadiusColumnLabel case final radiusLabel?)
            _SortHeader(
              key: const ValueKey('chart-table-header-radius'),
              label: radiusLabel,
              columnId: 'radius',
              width: tableTheme.seriesColumnWidth,
              controller: _controller,
              theme: tableTheme,
              numeric: true,
            ),
          _SortHeader(
            key: const ValueKey('chart-table-header-share'),
            label: 'Share',
            columnId: 'share',
            width: tableTheme.seriesColumnWidth,
            controller: _controller,
            theme: tableTheme,
            numeric: true,
          ),
        ],
      );
    }
    if (model.projectionKind == ChartTableProjectionKind.cartesianWide) {
      return _TableHeader(
        theme: tableTheme,
        children: [
          if (widget.showCopyRowAction)
            _StaticHeader(
              key: const ValueKey('chart-table-header-row-actions'),
              label: '',
              semanticsLabel: 'Row actions',
              width: 44,
              theme: tableTheme,
            ),
          _StaticHeader(
            key: const ValueKey('chart-table-header-index'),
            label: '#',
            width: tableTheme.rowNumberWidth,
            theme: tableTheme,
            numeric: true,
          ),
          _SortHeader(
            key: const ValueKey('chart-table-header-x'),
            label: model.xColumnLabel,
            columnId: 'x',
            width: tableTheme.xColumnWidth,
            controller: _controller,
            theme: tableTheme,
            numeric: true,
          ),
          for (final column in model.series)
            _SortHeader(
              label: column.unit == null
                  ? column.seriesName
                  : '${column.seriesName} (${column.unit})',
              columnId: 'series:${column.seriesId}',
              width: tableTheme.seriesColumnWidth,
              controller: _controller,
              theme: tableTheme,
              hidden: column.hidden,
              numeric: true,
              seriesColor: column.colorValue == null
                  ? null
                  : Color(column.colorValue!),
            ),
        ],
      );
    }
    return _TableHeader(
      theme: tableTheme,
      children: [
        if (widget.showCopyRowAction)
          _StaticHeader(
            key: const ValueKey('chart-table-header-row-actions'),
            label: '',
            semanticsLabel: 'Row actions',
            width: 44,
            theme: tableTheme,
          ),
        _StaticHeader(
          key: const ValueKey('chart-table-header-index'),
          label: '#',
          width: tableTheme.rowNumberWidth,
          theme: tableTheme,
          numeric: true,
        ),
        _SortHeader(
          label: 'Series',
          columnId: 'series',
          width: 192,
          controller: _controller,
          theme: tableTheme,
        ),
        _SortHeader(
          label: model.xColumnLabel,
          columnId: 'x',
          width: tableTheme.xColumnWidth,
          controller: _controller,
          theme: tableTheme,
          numeric: true,
        ),
        _SortHeader(
          label: 'Y value',
          columnId: 'y',
          width: tableTheme.seriesColumnWidth,
          controller: _controller,
          theme: tableTheme,
          numeric: true,
        ),
        _StaticHeader(label: 'Unit', width: 88, theme: tableTheme),
        _StaticHeader(label: 'Label', width: 144, theme: tableTheme),
        _StaticHeader(label: 'Status', width: 96, theme: tableTheme),
      ],
    );
  }

  Widget _buildRow(
    ChartTableModel model,
    int index, {
    required List<ChartTableLongRow> longRows,
    required List<ChartTableWideRow> wideRows,
    required List<ChartTablePieRow> pieRows,
    required _ResolvedTableTheme theme,
  }) {
    if (model.projectionKind == ChartTableProjectionKind.pie) {
      final row = pieRows[index];
      final references = List<ChartPointRef>.unmodifiable([row.reference]);
      final unitSuffix = row.unit == null ? '' : ' ${row.unit}';
      final radiusSemantics = row.radiusLabel == null
          ? ''
          : ', ${row.radiusLabel}, ${row.radiusDisplay ?? 'No value'}${row.radiusUnit == null ? '' : ' ${row.radiusUnit}'}';
      return _FocusableTableRow(
        key: ValueKey(row.rowId),
        semanticsLabel:
            'Row ${index + 1}, ${row.category}, ${row.valueDisplay}$unitSuffix$radiusSemantics, ${row.shareDisplay}, ${row.isValid ? 'valid slice' : 'invalid slice'}',
        references: references,
        selected: _isRowSelected(references),
        rowIndex: index,
        theme: theme,
        focusNode: _focusNodeFor(row.rowId),
        onMoveVertical: (delta) => _moveRowFocus(
          pieRows.length,
          (targetIndex) => pieRows[targetIndex].rowId,
          index,
          delta,
          theme.rowHeight,
        ),
        onMoveHorizontal: (delta) =>
            _moveHorizontal(delta, theme.seriesColumnWidth),
        onFocused: widget.onRowFocused,
        onFocusCleared: widget.onRowFocusCleared,
        onHoverChanged: widget.onRowHoverChanged,
        onActivated: widget.onRowActivated,
        children: [
          if (widget.showCopyRowAction)
            _CopyRowButton(
              tooltip: 'Copy ${row.category} row',
              onPressed: () =>
                  _copyRow(ChartTableExporter.pieRow(model, row, index), index),
            ),
          _TableCell(
            key: ValueKey('chart-table-row-index-$index'),
            text: '${index + 1}',
            width: theme.rowNumberWidth,
            numeric: true,
            theme: theme,
            rowNumber: true,
          ),
          _PieCategoryCell(row: row, width: 192, theme: theme),
          _TableCell(
            key: ValueKey('chart-table-cell-value-$index'),
            text: row.valueDisplay,
            width: theme.seriesColumnWidth,
            numeric: true,
            invalid: !row.isValid,
            color: row.colorValue == null ? null : Color(row.colorValue!),
            theme: theme,
          ),
          if (model.hasPieRadiusValues)
            _TableCell(
              key: ValueKey('chart-table-cell-radius-$index'),
              text: row.radiusDisplay ?? 'No value',
              width: theme.seriesColumnWidth,
              numeric: true,
              invalid: row.radiusRaw == null || !row.radiusRaw!.isFinite,
              color: row.colorValue == null ? null : Color(row.colorValue!),
              theme: theme,
            ),
          _TableCell(
            key: ValueKey('chart-table-cell-share-$index'),
            text: row.shareDisplay,
            width: theme.seriesColumnWidth,
            numeric: true,
            invalid: !row.isValid,
            theme: theme,
          ),
        ],
      );
    }
    if (model.projectionKind == ChartTableProjectionKind.cartesianWide) {
      final row = wideRows[index];
      final references = List<ChartPointRef>.unmodifiable(
        row.cells.values.map((cell) => cell.reference),
      );
      return _FocusableTableRow(
        key: ValueKey(row.rowId),
        semanticsLabel: 'Row ${index + 1}, ${_wideSemantics(row, model)}',
        references: references,
        selected: _isRowSelected(references),
        rowIndex: index,
        theme: theme,
        focusNode: _focusNodeFor(row.rowId),
        onMoveVertical: (delta) => _moveRowFocus(
          wideRows.length,
          (targetIndex) => wideRows[targetIndex].rowId,
          index,
          delta,
          theme.rowHeight,
        ),
        onMoveHorizontal: (delta) =>
            _moveHorizontal(delta, theme.seriesColumnWidth),
        onFocused: widget.onRowFocused,
        onFocusCleared: widget.onRowFocusCleared,
        onHoverChanged: widget.onRowHoverChanged,
        onActivated: widget.onRowActivated,
        children: [
          if (widget.showCopyRowAction)
            _CopyRowButton(
              tooltip: 'Copy row ${index + 1}',
              onPressed: () => _copyRow(
                ChartTableExporter.wideRow(model, row, index),
                index,
              ),
            ),
          _TableCell(
            key: ValueKey('chart-table-row-index-$index'),
            text: '${index + 1}',
            width: theme.rowNumberWidth,
            numeric: true,
            theme: theme,
            rowNumber: true,
          ),
          _TableCell(
            key: ValueKey('chart-table-cell-x-$index'),
            text: row.xDisplay,
            width: theme.xColumnWidth,
            numeric: true,
            theme: theme,
          ),
          for (final column in model.series)
            _buildWideValueCell(row, column, theme),
        ],
      );
    }
    final row = longRows[index];
    return _FocusableTableRow(
      key: ValueKey(row.rowId),
      semanticsLabel:
          'Row ${index + 1}, ${row.seriesName}, X ${row.xDisplay}, Y ${row.yDisplay}${row.unit == null ? '' : ' ${row.unit}'}, ${row.isValid ? 'valid point' : 'invalid point'}',
      references: List.unmodifiable([row.reference]),
      selected: _isRowSelected([row.reference]),
      rowIndex: index,
      theme: theme,
      focusNode: _focusNodeFor(row.rowId),
      onMoveVertical: (delta) => _moveRowFocus(
        longRows.length,
        (targetIndex) => longRows[targetIndex].rowId,
        index,
        delta,
        theme.rowHeight,
      ),
      onMoveHorizontal: (delta) =>
          _moveHorizontal(delta, theme.seriesColumnWidth),
      onFocused: widget.onRowFocused,
      onFocusCleared: widget.onRowFocusCleared,
      onHoverChanged: widget.onRowHoverChanged,
      onActivated: widget.onRowActivated,
      children: [
        if (widget.showCopyRowAction)
          _CopyRowButton(
            tooltip: 'Copy ${row.seriesName} row',
            onPressed: () =>
                _copyRow(ChartTableExporter.longRow(model, row, index), index),
          ),
        _TableCell(
          key: ValueKey('chart-table-row-index-$index'),
          text: '${index + 1}',
          width: theme.rowNumberWidth,
          numeric: true,
          theme: theme,
          rowNumber: true,
        ),
        _TableCell(
          text: row.seriesName,
          width: 192,
          secondary: row.hiddenSeries ? 'Hidden in chart' : null,
          theme: theme,
        ),
        _TableCell(
          text: row.xDisplay,
          width: theme.xColumnWidth,
          numeric: true,
          theme: theme,
        ),
        _TableCell(
          text: row.yDisplay,
          width: theme.seriesColumnWidth,
          numeric: true,
          invalid: !row.isValid,
          color: _seriesColor(model, row.reference.seriesId),
          theme: theme,
        ),
        _TableCell(text: row.unit ?? 'No unit', width: 88, theme: theme),
        _TableCell(text: row.label ?? 'No label', width: 144, theme: theme),
        _TableCell(
          text: row.isValid ? 'Valid' : 'No value',
          width: 96,
          invalid: !row.isValid,
          theme: theme,
        ),
      ],
    );
  }

  bool _isRowSelected(Iterable<ChartPointRef> references) {
    final points = references.toList(growable: false);
    return points.isNotEmpty && points.every(widget.selectedPointRefs.contains);
  }

  Widget _buildWideValueCell(
    ChartTableWideRow row,
    ChartTableSeriesColumn column,
    _ResolvedTableTheme theme,
  ) {
    final cell = row.cells[column.seriesId];
    return _TableCell(
      text: cell?.yDisplay ?? 'No value',
      width: theme.seriesColumnWidth,
      numeric: true,
      invalid: cell?.isValid == false,
      color: cell == null || column.colorValue == null
          ? null
          : Color(column.colorValue!),
      theme: theme,
    );
  }

  FocusNode _focusNodeFor(String rowId) =>
      _rowFocusNodes.putIfAbsent(rowId, () => FocusNode(debugLabel: rowId));

  void _moveRowFocus(
    int rowCount,
    String Function(int index) rowIdAt,
    int currentIndex,
    int delta,
    double rowHeight,
  ) {
    if (rowCount == 0) return;
    final targetIndex = (currentIndex + delta).clamp(0, rowCount - 1);
    if (targetIndex == currentIndex) return;
    final targetNode = _focusNodeFor(rowIdAt(targetIndex));
    if (_verticalController.hasClients) {
      final position = _verticalController.position;
      final rowTop = targetIndex * rowHeight;
      final rowBottom = rowTop + rowHeight;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      final targetOffset = rowTop < viewportTop
          ? rowTop
          : rowBottom > viewportBottom
          ? rowBottom - position.viewportDimension
          : viewportTop;
      _verticalController.jumpTo(
        targetOffset.clamp(0, position.maxScrollExtent),
      );
    }
    targetNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !targetNode.hasFocus) targetNode.requestFocus();
    });
  }

  void _moveHorizontal(int delta, double columnWidth) {
    if (!_horizontalController.hasClients) return;
    final position = _horizontalController.position;
    _horizontalController.animateTo(
      (position.pixels + delta * columnWidth).clamp(
        0,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  List<ChartTableLongRow> _sortedLongRows(ChartTableModel model) {
    final rows = [...model.longRows];
    final column = _controller.sortColumnId;
    if (column == null) return rows;
    rows.sort((left, right) {
      final result = switch (column) {
        'series' => left.seriesName.compareTo(right.seriesName),
        'x' => _compareNumbers(left.xRaw, right.xRaw),
        'y' => _compareNumbers(left.yRaw, right.yRaw),
        _ => 0,
      };
      return _controller.sortAscending ? result : -result;
    });
    return rows;
  }

  List<ChartTableWideRow> _sortedWideRows(ChartTableModel model) {
    final rows = [...model.wideRows];
    final column = _controller.sortColumnId;
    if (column == null) return rows;
    rows.sort((left, right) {
      final result = column == 'x'
          ? _compareNumbers(left.xRaw, right.xRaw)
          : column.startsWith('series:')
          ? _compareNullableNumbers(
              left.cells[column.substring(7)]?.yRaw,
              right.cells[column.substring(7)]?.yRaw,
            )
          : 0;
      return _controller.sortAscending ? result : -result;
    });
    return rows;
  }

  List<ChartTablePieRow> _sortedPieRows(ChartTableModel model) {
    final rows = [...model.pieRows];
    final column = _controller.sortColumnId;
    if (column == null) return rows;
    rows.sort((left, right) {
      final result = switch (column) {
        'category' => left.category.toLowerCase().compareTo(
          right.category.toLowerCase(),
        ),
        'value' => _compareNumbers(left.valueRaw, right.valueRaw),
        'radius' => _compareNullableNumbers(left.radiusRaw, right.radiusRaw),
        'share' => _compareNumbers(left.shareRaw, right.shareRaw),
        _ => 0,
      };
      return _controller.sortAscending ? result : -result;
    });
    return rows;
  }

  Color? _seriesColor(ChartTableModel model, String seriesId) {
    for (final column in model.series) {
      if (column.seriesId == seriesId) {
        return column.colorValue == null ? null : Color(column.colorValue!);
      }
    }
    return null;
  }
}

class _TableSummary extends StatelessWidget {
  const _TableSummary({
    required this.model,
    required this.theme,
    this.onCopyDataset,
    this.onExportCsv,
  });

  final ChartTableModel model;
  final _ResolvedTableTheme theme;
  final VoidCallback? onCopyDataset;
  final VoidCallback? onExportCsv;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compactActions = constraints.maxWidth < 520;
      Widget action({
        required String label,
        required IconData icon,
        required VoidCallback onPressed,
      }) => compactActions
          ? IconButton(
              tooltip: label,
              onPressed: onPressed,
              visualDensity: VisualDensity.compact,
              icon: Icon(icon, size: 18),
            )
          : TextButton.icon(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: theme.summaryTextStyle,
              ),
              icon: Icon(icon, size: 16),
              label: Text(label),
            );

      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${model.scopeLabel} · ${model.rowCount} rows · ${model.options.viewportOnly ? 'Current viewport' : 'Full data'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.summaryTextStyle,
              ),
            ),
            if (onCopyDataset != null)
              action(
                label: 'Copy data',
                icon: Icons.content_copy_outlined,
                onPressed: onCopyDataset!,
              ),
            if (onExportCsv != null)
              action(
                label: 'Export CSV',
                icon: Icons.download_outlined,
                onPressed: onExportCsv!,
              ),
          ],
        ),
      );
    },
  );
}

class _TableWarningBanner extends StatelessWidget {
  const _TableWarningBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        color: colors.tertiaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count formatter ${count == 1 ? 'warning' : 'warnings'}; fallback values are shown.',
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.children, required this.theme});

  final List<Widget> children;
  final _ResolvedTableTheme theme;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Table column headers',
    child: Container(
      height: theme.headerHeight,
      decoration: BoxDecoration(
        color: theme.headerBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(children: children),
    ),
  );
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    super.key,
    required this.label,
    required this.columnId,
    required this.width,
    required this.controller,
    required this.theme,
    this.hidden = false,
    this.numeric = false,
    this.seriesColor,
  });

  final String label;
  final String columnId;
  final double width;
  final ChartTableController controller;
  final _ResolvedTableTheme theme;
  final bool hidden;
  final bool numeric;
  final Color? seriesColor;

  @override
  Widget build(BuildContext context) {
    final selected = controller.sortColumnId == columnId;
    final direction = selected
        ? controller.sortAscending
              ? 'ascending'
              : 'descending'
        : 'not sorted';
    return Semantics(
      label: '$label, $direction${hidden ? ', hidden in chart' : ''}',
      button: true,
      excludeSemantics: true,
      onTap: () => controller.sortBy(columnId),
      child: SizedBox(
        width: width,
        height: theme.headerHeight,
        child: InkWell(
          onTap: () => controller.sortBy(columnId),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.cellHorizontalPadding,
            ),
            child: Row(
              mainAxisAlignment: numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (seriesColor != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Semantics(
                      label: '$label series color',
                      child: DecoratedBox(
                        key: ValueKey('chart-table-series-color-$columnId'),
                        decoration: BoxDecoration(
                          color: seriesColor,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    key: ValueKey('chart-table-header-text-$columnId'),
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: numeric ? TextAlign.right : TextAlign.left,
                    style: theme.headerTextStyle,
                  ),
                ),
                if (hidden)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.visibility_off_outlined, size: 14),
                  ),
                if (selected)
                  Icon(
                    controller.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 15,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticHeader extends StatelessWidget {
  const _StaticHeader({
    super.key,
    required this.label,
    required this.width,
    required this.theme,
    this.numeric = false,
    this.semanticsLabel,
  });

  final String label;
  final double width;
  final _ResolvedTableTheme theme;
  final bool numeric;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: semanticsLabel != null,
    label: semanticsLabel,
    excludeSemantics: semanticsLabel != null,
    child: SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.cellHorizontalPadding),
        child: Text(
          label,
          textAlign: numeric ? TextAlign.right : TextAlign.left,
          style: theme.headerTextStyle,
        ),
      ),
    ),
  );
}

class _CopyRowButton extends StatelessWidget {
  const _CopyRowButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.copy_outlined, size: 16),
    ),
  );
}

class _MoveTableFocusIntent extends Intent {
  const _MoveTableFocusIntent({this.vertical = 0, this.horizontal = 0});

  final int vertical;
  final int horizontal;
}

class _FocusableTableRow extends StatefulWidget {
  const _FocusableTableRow({
    super.key,
    required this.semanticsLabel,
    required this.references,
    required this.selected,
    required this.children,
    required this.rowIndex,
    required this.theme,
    required this.focusNode,
    required this.onMoveVertical,
    required this.onMoveHorizontal,
    this.onFocused,
    this.onFocusCleared,
    this.onHoverChanged,
    this.onActivated,
  });

  final String semanticsLabel;
  final List<ChartPointRef> references;
  final bool selected;
  final List<Widget> children;
  final int rowIndex;
  final _ResolvedTableTheme theme;
  final FocusNode focusNode;
  final ValueChanged<int> onMoveVertical;
  final ValueChanged<int> onMoveHorizontal;
  final ChartTableRowCallback? onFocused;
  final VoidCallback? onFocusCleared;
  final ChartTableRowHoverCallback? onHoverChanged;
  final ChartTableRowCallback? onActivated;

  @override
  State<_FocusableTableRow> createState() => _FocusableTableRowState();
}

class _FocusableTableRowState extends State<_FocusableTableRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: widget.onActivated != null,
      focused: _focused,
      selected: widget.selected,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): _MoveTableFocusIntent(
            vertical: -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowDown): _MoveTableFocusIntent(
            vertical: 1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveTableFocusIntent(
            horizontal: -1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): _MoveTableFocusIntent(
            horizontal: 1,
          ),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          _MoveTableFocusIntent: CallbackAction<_MoveTableFocusIntent>(
            onInvoke: (intent) {
              if (intent.vertical != 0) {
                widget.onMoveVertical(intent.vertical);
              }
              if (intent.horizontal != 0) {
                widget.onMoveHorizontal(intent.horizontal);
              }
              return null;
            },
          ),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onActivated?.call(widget.references);
              return null;
            },
          ),
        },
        onFocusChange: (focused) {
          if (_focused != focused) setState(() => _focused = focused);
          if (focused) {
            widget.onFocused?.call(widget.references);
          } else {
            widget.onFocusCleared?.call();
          }
        },
        mouseCursor: widget.onActivated == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: InkWell(
          canRequestFocus: false,
          onTap: widget.onActivated == null
              ? null
              : () => widget.onActivated!(widget.references),
          onHover: (hovering) {
            widget.onHoverChanged?.call(hovering ? widget.references : null);
          },
          child: Container(
            height: widget.theme.rowHeight,
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.theme.selectedRowColor
                  : _focused
                  ? widget.theme.focusedRowColor
                  : widget.rowIndex.isEven
                  ? widget.theme.evenRowColor
                  : widget.theme.oddRowColor,
              border: Border(
                bottom: BorderSide(color: widget.theme.dividerColor),
              ),
            ),
            foregroundDecoration: _focused || widget.selected
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: widget.theme.focusBorderColor,
                        width: widget.selected
                            ? math.max(4, widget.theme.focusBorderWidth)
                            : widget.theme.focusBorderWidth,
                      ),
                      top: _focused
                          ? BorderSide(
                              color: widget.theme.focusBorderColor,
                              width: widget.theme.focusBorderWidth,
                            )
                          : BorderSide.none,
                      right: _focused
                          ? BorderSide(
                              color: widget.theme.focusBorderColor,
                              width: widget.theme.focusBorderWidth,
                            )
                          : BorderSide.none,
                      bottom: _focused
                          ? BorderSide(
                              color: widget.theme.focusBorderColor,
                              width: widget.theme.focusBorderWidth,
                            )
                          : BorderSide.none,
                    ),
                  )
                : null,
            child: Row(children: widget.children),
          ),
        ),
      ),
    );
  }
}

class _TableSelectionBoundary extends StatelessWidget {
  const _TableSelectionBoundary({
    required this.enableSelection,
    required this.child,
  });

  final bool enableSelection;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      enableSelection ? SelectionArea(child: child) : child;
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    super.key,
    required this.text,
    required this.width,
    this.secondary,
    this.numeric = false,
    this.invalid = false,
    this.color,
    this.rowNumber = false,
    required this.theme,
  });

  final String text;
  final String? secondary;
  final double width;
  final bool numeric;
  final bool invalid;
  final Color? color;
  final bool rowNumber;
  final _ResolvedTableTheme theme;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        (rowNumber ? theme.rowNumberTextStyle : theme.cellTextStyle).copyWith(
          color: invalid ? Theme.of(context).colorScheme.error : color,
          fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
        );
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.cellHorizontalPadding),
        child: secondary == null
            ? Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: numeric ? TextAlign.right : TextAlign.left,
                style: textStyle,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    secondary!,
                    maxLines: 1,
                    style: theme.secondaryTextStyle,
                  ),
                ],
              ),
      ),
    );
  }
}

class _PieCategoryCell extends StatelessWidget {
  const _PieCategoryCell({
    required this.row,
    required this.width,
    required this.theme,
  });

  final ChartTablePieRow row;
  final double width;
  final _ResolvedTableTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.cellHorizontalPadding),
        child: Row(
          children: [
            if (row.colorValue != null) ...[
              Semantics(
                label: '${row.category} slice color',
                child: DecoratedBox(
                  key: ValueKey(
                    'chart-table-pie-color-${row.reference.pointIndex}',
                  ),
                  decoration: BoxDecoration(
                    color: Color(row.colorValue!),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: const SizedBox.square(dimension: 10),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                row.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: row.isValid
                    ? theme.cellTextStyle
                    : theme.cellTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableLoadingState extends StatelessWidget {
  const _TableLoadingState();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Loading chart data',
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading chart data…'),
        ],
      ),
    ),
  );
}

class _TableMessageState extends StatelessWidget {
  const _TableMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedTableTheme {
  const _ResolvedTableTheme({
    required this.rowHeight,
    required this.headerHeight,
    required this.rowNumberWidth,
    required this.xColumnWidth,
    required this.seriesColumnWidth,
    required this.cellHorizontalPadding,
    required this.headerBackgroundColor,
    required this.evenRowColor,
    required this.oddRowColor,
    required this.dividerColor,
    required this.focusedRowColor,
    required this.selectedRowColor,
    required this.focusBorderColor,
    required this.focusBorderWidth,
    required this.headerTextStyle,
    required this.cellTextStyle,
    required this.rowNumberTextStyle,
    required this.secondaryTextStyle,
    required this.summaryTextStyle,
  });

  factory _ResolvedTableTheme.from(
    BuildContext context,
    ChartDataTableTheme? override,
  ) {
    final source = override ?? const ChartDataTableTheme();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final headerTextStyle =
        source.headerTextStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        );
    final cellTextStyle =
        source.cellTextStyle ??
        theme.textTheme.bodySmall?.copyWith(color: colors.onSurface) ??
        TextStyle(color: colors.onSurface, fontSize: 12);
    return _ResolvedTableTheme(
      rowHeight: math.max(
        source.rowHeight,
        _scaledLineHeight(cellTextStyle, textScaler) + 12,
      ),
      headerHeight: math.max(
        source.headerHeight,
        _scaledLineHeight(headerTextStyle, textScaler) + 16,
      ),
      rowNumberWidth: source.rowNumberWidth,
      xColumnWidth: source.xColumnWidth,
      seriesColumnWidth: source.seriesColumnWidth,
      cellHorizontalPadding: source.cellHorizontalPadding,
      headerBackgroundColor:
          source.headerBackgroundColor ?? colors.surfaceContainerHigh,
      evenRowColor: source.evenRowColor ?? colors.surface,
      oddRowColor: source.oddRowColor ?? colors.surfaceContainerLowest,
      dividerColor:
          source.dividerColor ??
          (highContrast
              ? colors.outline
              : colors.outlineVariant.withValues(alpha: 0.65)),
      focusedRowColor: source.focusedRowColor ?? colors.primaryContainer,
      selectedRowColor:
          source.selectedRowColor ??
          colors.primaryContainer.withValues(alpha: 0.72),
      focusBorderColor: colors.primary,
      focusBorderWidth: highContrast ? 3 : 2,
      headerTextStyle: headerTextStyle,
      cellTextStyle: cellTextStyle,
      rowNumberTextStyle:
          source.rowNumberTextStyle ??
          theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ) ??
          TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      secondaryTextStyle:
          theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 10,
          ) ??
          TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
      summaryTextStyle:
          theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ) ??
          TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
    );
  }

  final double rowHeight;
  final double headerHeight;
  final double rowNumberWidth;
  final double xColumnWidth;
  final double seriesColumnWidth;
  final double cellHorizontalPadding;
  final Color headerBackgroundColor;
  final Color evenRowColor;
  final Color oddRowColor;
  final Color dividerColor;
  final Color focusedRowColor;
  final Color selectedRowColor;
  final Color focusBorderColor;
  final double focusBorderWidth;
  final TextStyle headerTextStyle;
  final TextStyle cellTextStyle;
  final TextStyle rowNumberTextStyle;
  final TextStyle secondaryTextStyle;
  final TextStyle summaryTextStyle;
}

double _scaledLineHeight(TextStyle style, TextScaler scaler) {
  final fontSize = style.fontSize ?? 12;
  return scaler.scale(fontSize) * (style.height ?? 1.2);
}

int _compareNumbers(double left, double right) {
  if (!left.isFinite && !right.isFinite) return 0;
  if (!left.isFinite) return 1;
  if (!right.isFinite) return -1;
  return left.compareTo(right);
}

int _compareNullableNumbers(double? left, double? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return _compareNumbers(left, right);
}

String _wideSemantics(ChartTableWideRow row, ChartTableModel model) {
  final values = [
    for (final column in model.series)
      '${column.seriesName} ${row.cells[column.seriesId]?.yDisplay ?? 'No value'}',
  ];
  return 'X ${row.xDisplay}, ${values.join(', ')}';
}
