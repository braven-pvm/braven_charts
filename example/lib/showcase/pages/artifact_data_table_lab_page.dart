import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Interactive proof that chart and table share one captured document.
class ArtifactDataTableLabPage extends StatefulWidget {
  const ArtifactDataTableLabPage({super.key});

  @override
  State<ArtifactDataTableLabPage> createState() =>
      _ArtifactDataTableLabPageState();
}

class _ArtifactDataTableLabPageState extends State<ArtifactDataTableLabPage> {
  final _chartController = BravenChartController();
  final _tableController = ChartTableController();
  ChartDocumentSnapshot? _snapshot;
  ChartTableModel? _model;
  ChartArtifactError? _error;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  ChartTableRowLayout _rowLayout = ChartTableRowLayout.long;
  ChartTableDataScope _scope = ChartTableDataScope.allSeries;
  bool _viewportOnly = false;
  bool _heartRateVisible = true;
  String _status = 'Capturing the mounted chart…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureDocument());
  }

  @override
  void dispose() {
    _chartController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  void _captureDocument() {
    final result = _chartController.extractDocument(
      ChartDocumentExtractOptions(
        documentId: 'data-table-lab',
        xAxisFormatterDescriptor: ChartFormatterDescriptor(
          id: 'braven.number.fixed',
          arguments: {'decimals': JsonNumberValue(0)},
        ).toDocument(),
      ),
    );
    switch (result) {
      case ChartArtifactSuccess<ChartDocumentSnapshot>():
        setState(() {
          _snapshot = result.value;
          _error = null;
          _status =
              'Document revision ${result.value.document.revision} captured from the live chart.';
          _rebuildTable();
        });
      case ChartArtifactFailure<ChartDocumentSnapshot>():
        setState(() {
          _error = result.error;
          _status = '${result.error.code}: ${result.error.message}';
        });
    }
  }

  void _rebuildTable() {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    _model = ChartTableModel.fromDocument(
      snapshot.document,
      viewState: snapshot.viewState,
      options: ChartTableOptions(
        dataScope: _scope,
        rowLayout: _rowLayout,
        viewportOnly: _viewportOnly,
      ),
    );
  }

  void _updateTable(VoidCallback update) {
    setState(() {
      update();
      _rebuildTable();
    });
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _chartController.setSeriesVisible('heart-rate', _heartRateVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureDocument());
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final effectiveMode = compact && _displayMode == ChartDisplayMode.split
        ? ChartDisplayMode.chart
        : _displayMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Data Table Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _captureDocument,
                    tooltip: 'Recapture chart document',
                    icon: const Icon(Icons.refresh),
                  )
                : FilledButton.icon(
                    onPressed: _captureDocument,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recapture document'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One document, 2 native views',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The chart and virtualized table below use the same captured '
                  'ChartDocument. Switch modes without resetting the live chart.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPrimaryControls(compact, effectiveMode),
                const SizedBox(height: 16),
                _buildTableControls(compact),
                const SizedBox(height: 16),
                _StatusStrip(
                  status: _status,
                  error: _error != null,
                  rowCount: _model?.rowCount,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: compact ? 520 : 600,
                  child: _buildModeStage(effectiveMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryControls(bool compact, ChartDisplayMode effectiveMode) =>
      Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<ChartDisplayMode>(
            segments: [
              const ButtonSegment(
                value: ChartDisplayMode.chart,
                icon: Icon(Icons.show_chart),
                label: Text('Chart'),
              ),
              const ButtonSegment(
                value: ChartDisplayMode.data,
                icon: Icon(Icons.table_rows_outlined),
                label: Text('Data'),
              ),
              if (!compact)
                const ButtonSegment(
                  value: ChartDisplayMode.split,
                  icon: Icon(Icons.vertical_split_outlined),
                  label: Text('Split'),
                ),
            ],
            selected: {effectiveMode},
            onSelectionChanged: (selection) {
              setState(() => _displayMode = selection.single);
            },
          ),
          OutlinedButton.icon(
            onPressed: _toggleHeartRate,
            icon: Icon(
              _heartRateVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            label: Text(
              _heartRateVisible ? 'Hide heart rate' : 'Show heart rate',
            ),
          ),
        ],
      );

  Widget _buildTableControls(bool compact) => Wrap(
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SegmentedButton<ChartTableRowLayout>(
        segments: const [
          ButtonSegment(
            value: ChartTableRowLayout.long,
            label: Text('Long rows'),
          ),
          ButtonSegment(
            value: ChartTableRowLayout.wide,
            label: Text('Exact-X wide'),
          ),
        ],
        selected: {_rowLayout},
        onSelectionChanged: (selection) =>
            _updateTable(() => _rowLayout = selection.single),
      ),
      SegmentedButton<ChartTableDataScope>(
        segments: const [
          ButtonSegment(
            value: ChartTableDataScope.allSeries,
            label: Text('All series'),
          ),
          ButtonSegment(
            value: ChartTableDataScope.visibleSeries,
            label: Text('Visible only'),
          ),
        ],
        selected: {_scope},
        onSelectionChanged: (selection) =>
            _updateTable(() => _scope = selection.single),
      ),
      FilterChip(
        selected: _viewportOnly,
        onSelected: (value) => _updateTable(() => _viewportOnly = value),
        avatar: const Icon(Icons.crop_free, size: 18),
        label: Text(compact ? 'Viewport' : 'Current viewport only'),
      ),
    ],
  );

  Widget _buildModeStage(ChartDisplayMode mode) => LayoutBuilder(
    builder: (context, constraints) {
      final gap = mode == ChartDisplayMode.split ? 16.0 : 0.0;
      final halfWidth = math.max(0.0, (constraints.maxWidth - gap) / 2);
      final showChart = mode != ChartDisplayMode.data;
      final showTable = mode != ChartDisplayMode.chart;
      return Stack(
        children: [
          Positioned(
            key: const ValueKey('chart-stage'),
            left: 0,
            top: 0,
            bottom: 0,
            width: mode == ChartDisplayMode.split
                ? halfWidth
                : constraints.maxWidth,
            child: Visibility(
              visible: showChart,
              maintainState: true,
              maintainAnimation: true,
              child: _chartPanel(),
            ),
          ),
          Positioned(
            key: const ValueKey('table-stage'),
            right: 0,
            top: 0,
            bottom: 0,
            width: mode == ChartDisplayMode.split
                ? halfWidth
                : constraints.maxWidth,
            child: Visibility(
              visible: showTable,
              maintainState: true,
              maintainAnimation: true,
              child: _tablePanel(),
            ),
          ),
        ],
      );
    },
  );

  Widget _chartPanel() => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: BravenChartPlus(
        bravenChartController: _chartController,
        title: 'Training response',
        subtitle: '160 points per series',
        xAxisConfig: XAxisConfig(
          label: 'Sample',
          labelFormatter: (value) => value.toStringAsFixed(0),
        ),
        series: [
          LineChartSeries(
            id: 'power',
            name: 'Power',
            unit: 'W',
            color: const Color(0xFF2563EB),
            points: _points(
              (index) => 210 + math.sin(index / 10) * 45 + index * 0.35,
            ),
          ),
          LineChartSeries(
            id: 'heart-rate',
            name: 'Heart rate',
            unit: 'bpm',
            color: const Color(0xFFDC2626),
            points: _points(
              (index) => 125 + math.sin(index / 16) * 18 + index * 0.16,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tablePanel() => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ChartDataTable(
      model: _model,
      isLoading: _model == null && _error == null,
      errorMessage: _error?.message,
      controller: _tableController,
      onCopyRow: (row) => setState(() {
        _status =
            'Copy hook: ${row.seriesName}, X ${row.xDisplay}, Y ${row.yDisplay}';
      }),
      onExportCsv: () => setState(() {
        _status = 'CSV hook received ${_model?.longRows.length ?? 0} raw rows.';
      }),
    ),
  );
}

List<ChartDataPoint> _points(double Function(int index) y) => [
  for (var index = 0; index < 160; index++)
    ChartDataPoint(
      x: index.toDouble(),
      y: y(index),
      label: index % 40 == 0 ? 'Interval ${index ~/ 40 + 1}' : null,
    ),
];

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.status,
    required this.error,
    required this.rowCount,
  });

  final String status;
  final bool error;
  final int? rowCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: error ? colors.errorContainer : colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline),
            Text(status),
            if (rowCount != null) Chip(label: Text('$rowCount table rows')),
          ],
        ),
      ),
    );
  }
}
