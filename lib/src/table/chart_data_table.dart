import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_table_controller.dart';
import 'chart_table_model.dart';
import 'chart_table_options.dart';

typedef ChartTableRowCallback = void Function(ChartTablePointReference point);

/// Accessible, horizontally scrollable, row-virtualized chart data table.
class ChartDataTable extends StatefulWidget {
  const ChartDataTable({
    super.key,
    this.model,
    this.controller,
    this.isLoading = false,
    this.errorMessage,
    this.onRowFocused,
    this.onRowActivated,
    this.onCopyRow,
    this.onExportCsv,
    this.emptyMessage = 'No chart data',
  }) : assert(
         model != null || isLoading || errorMessage != null,
         'Provide a model, loading state, or error message.',
       );

  final ChartTableModel? model;
  final ChartTableController? controller;
  final bool isLoading;
  final String? errorMessage;
  final ChartTableRowCallback? onRowFocused;
  final ChartTableRowCallback? onRowActivated;
  final ValueChanged<ChartTableLongRow>? onCopyRow;
  final VoidCallback? onExportCsv;
  final String emptyMessage;

  @override
  State<ChartDataTable> createState() => _ChartDataTableState();
}

class _ChartDataTableState extends State<ChartDataTable> {
  late ChartTableController _controller;
  late bool _ownsController;
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

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

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
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
    final longRows = model.options.rowLayout == ChartTableRowLayout.long
        ? _sortedLongRows(model)
        : const <ChartTableLongRow>[];
    final wideRows = model.options.rowLayout == ChartTableRowLayout.wide
        ? _sortedWideRows(model)
        : const <ChartTableWideRow>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 960.0;
        final contentWidth = model.options.rowLayout == ChartTableRowLayout.long
            ? math.max(viewportWidth, widget.onCopyRow == null ? 880.0 : 936.0)
            : math.max(viewportWidth, 176.0 + model.series.length * 152.0);
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TableSummary(model: model, onExportCsv: widget.onExportCsv),
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
                          _buildHeader(model),
                          Expanded(
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: SelectionArea(
                                child: ListView.builder(
                                  controller: _verticalController,
                                  itemExtent: 56,
                                  itemCount: model.rowCount,
                                  itemBuilder: (context, index) => _buildRow(
                                    model,
                                    index,
                                    longRows: longRows,
                                    wideRows: wideRows,
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

  Widget _buildHeader(ChartTableModel model) {
    if (model.options.rowLayout == ChartTableRowLayout.wide) {
      return _TableHeader(
        children: [
          _SortHeader(
            label: 'X value',
            columnId: 'x',
            width: 176,
            controller: _controller,
          ),
          for (final column in model.series)
            _SortHeader(
              label: column.unit == null
                  ? column.seriesName
                  : '${column.seriesName} (${column.unit})',
              columnId: 'series:${column.seriesId}',
              width: 152,
              controller: _controller,
              hidden: column.hidden,
            ),
        ],
      );
    }
    return _TableHeader(
      children: [
        _SortHeader(
          label: 'Series',
          columnId: 'series',
          width: 208,
          controller: _controller,
        ),
        _SortHeader(
          label: 'X value',
          columnId: 'x',
          width: 144,
          controller: _controller,
        ),
        _SortHeader(
          label: 'Y value',
          columnId: 'y',
          width: 144,
          controller: _controller,
        ),
        const _StaticHeader(label: 'Unit', width: 104),
        const _StaticHeader(label: 'Label', width: 168),
        const _StaticHeader(label: 'Status', width: 112),
        if (widget.onCopyRow != null)
          const _StaticHeader(label: 'Actions', width: 56),
      ],
    );
  }

  Widget _buildRow(
    ChartTableModel model,
    int index, {
    required List<ChartTableLongRow> longRows,
    required List<ChartTableWideRow> wideRows,
  }) {
    if (model.options.rowLayout == ChartTableRowLayout.wide) {
      final row = wideRows[index];
      final firstReference = row.cells.values.first.reference;
      return _FocusableTableRow(
        key: ValueKey(row.rowId),
        semanticsLabel: _wideSemantics(row, model),
        reference: firstReference,
        onFocused: widget.onRowFocused,
        onActivated: widget.onRowActivated,
        children: [
          _TableCell(text: row.xDisplay, width: 176, numeric: true),
          for (final column in model.series)
            _TableCell(
              text: row.cells[column.seriesId]?.yDisplay ?? 'No value',
              width: 152,
              numeric: true,
              invalid: row.cells[column.seriesId]?.isValid == false,
            ),
        ],
      );
    }
    final row = longRows[index];
    return _FocusableTableRow(
      key: ValueKey(row.rowId),
      semanticsLabel:
          '${row.seriesName}, X ${row.xDisplay}, Y ${row.yDisplay}${row.unit == null ? '' : ' ${row.unit}'}, ${row.isValid ? 'valid point' : 'invalid point'}',
      reference: row.reference,
      onFocused: widget.onRowFocused,
      onActivated: widget.onRowActivated,
      children: [
        _TableCell(
          text: row.seriesName,
          width: 208,
          secondary: row.hiddenSeries ? 'Hidden in chart' : null,
        ),
        _TableCell(text: row.xDisplay, width: 144, numeric: true),
        _TableCell(
          text: row.yDisplay,
          width: 144,
          numeric: true,
          invalid: !row.isValid,
        ),
        _TableCell(text: row.unit ?? 'No unit', width: 104),
        _TableCell(text: row.label ?? 'No label', width: 168),
        _TableCell(
          text: row.isValid ? 'Valid' : 'No value',
          width: 112,
          invalid: !row.isValid,
        ),
        if (widget.onCopyRow != null)
          SizedBox(
            width: 56,
            child: IconButton(
              tooltip: 'Copy ${row.seriesName} row',
              onPressed: () => widget.onCopyRow!(row),
              icon: const Icon(Icons.copy_outlined, size: 20),
            ),
          ),
      ],
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
}

class _TableSummary extends StatelessWidget {
  const _TableSummary({required this.model, this.onExportCsv});

  final ChartTableModel model;
  final VoidCallback? onExportCsv;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${model.scopeLabel} · ${model.rowCount} rows · ${model.options.viewportOnly ? 'Current viewport' : 'Full data'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        if (onExportCsv != null)
          TextButton.icon(
            onPressed: onExportCsv,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export CSV'),
          ),
      ],
    ),
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
  const _TableHeader({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Table column headers',
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(children: children),
    ),
  );
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.columnId,
    required this.width,
    required this.controller,
    this.hidden = false,
  });

  final String label;
  final String columnId;
  final double width;
  final ChartTableController controller;
  final bool hidden;

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
        height: 56,
        child: InkWell(
          onTap: () => controller.sortBy(columnId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (hidden)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.visibility_off_outlined, size: 16),
                  ),
                if (selected)
                  Icon(
                    controller.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 18,
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
  const _StaticHeader({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class _FocusableTableRow extends StatefulWidget {
  const _FocusableTableRow({
    super.key,
    required this.semanticsLabel,
    required this.reference,
    required this.children,
    this.onFocused,
    this.onActivated,
  });

  final String semanticsLabel;
  final ChartTablePointReference reference;
  final List<Widget> children;
  final ChartTableRowCallback? onFocused;
  final ChartTableRowCallback? onActivated;

  @override
  State<_FocusableTableRow> createState() => _FocusableTableRowState();
}

class _FocusableTableRowState extends State<_FocusableTableRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.semanticsLabel,
      button: widget.onActivated != null,
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onFocusChange: (focused) {
          if (focused) widget.onFocused?.call(widget.reference);
        },
        mouseCursor: widget.onActivated == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onActivated == null
              ? null
              : () => widget.onActivated!(widget.reference),
          onHover: (hovering) {
            if (hovering) widget.onFocused?.call(widget.reference);
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _focused ? colors.primaryContainer : null,
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
                left: _focused
                    ? BorderSide(color: colors.primary, width: 3)
                    : BorderSide.none,
              ),
            ),
            child: Row(children: widget.children),
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    required this.width,
    this.secondary,
    this.numeric = false,
    this.invalid = false,
  });

  final String text;
  final String? secondary;
  final double width;
  final bool numeric;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: invalid ? Theme.of(context).colorScheme.error : null,
      fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
    );
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    style: Theme.of(context).textTheme.labelSmall,
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
