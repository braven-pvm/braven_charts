import 'dart:convert';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Live comparison of lossless point-object and columnar artifact payloads.
class ArtifactPayloadLabPage extends StatefulWidget {
  const ArtifactPayloadLabPage({super.key});

  @override
  State<ArtifactPayloadLabPage> createState() => _ArtifactPayloadLabPageState();
}

class _ArtifactPayloadLabPageState extends State<ArtifactPayloadLabPage> {
  final _controller = BravenChartController();
  ChartTableModel? _table;
  int? _pointBytes;
  int? _columnBytes;
  int? _hydratedPoints;
  String _status = 'Compare both lossless inline storage projections.';
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _comparePayloads() {
    final pointResult = _controller.extractDocument(
      const ChartDocumentExtractOptions(
        documentId: 'payload-lab',
        dataStorage: ChartDataStorage.inlinePoints,
      ),
    );
    final columnResult = _controller.extractDocument(
      const ChartDocumentExtractOptions(
        documentId: 'payload-lab',
        dataStorage: ChartDataStorage.inlineColumns,
      ),
    );
    if (pointResult case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      _showError(pointResult.error);
      return;
    }
    if (columnResult case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      _showError(columnResult.error);
      return;
    }

    final pointSnapshot =
        (pointResult as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
    final columnSnapshot =
        (columnResult as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
    final capturedAt = DateTime.utc(2026, 7, 15, 8);
    final pointJson = _encode(_artifact(pointSnapshot, capturedAt: capturedAt));
    final columnJson = _encode(
      _artifact(columnSnapshot, capturedAt: capturedAt),
    );
    if (pointJson == null || columnJson == null) return;

    final decoded = ChartArtifactJsonCodec.decode(
      columnJson,
      supportedCapabilities: const {'series.line'},
    );
    if (decoded case ChartArtifactFailure<ChartArtifactDecodeResult>()) {
      _showError(decoded.error);
      return;
    }
    final decodedArtifact =
        (decoded as ChartArtifactSuccess<ChartArtifactDecodeResult>)
            .value
            .artifact;
    final hydrated = ChartDocumentHydrator.hydrateArtifact(decodedArtifact);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      _showError(hydrated.error);
      return;
    }
    final configuration =
        (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    final table = ChartTableModel.fromDocument(
      decodedArtifact.document,
      viewState: decodedArtifact.viewState,
    );
    final pointBytes = utf8.encode(pointJson).length;
    final columnBytes = utf8.encode(columnJson).length;

    setState(() {
      _error = false;
      _pointBytes = pointBytes;
      _columnBytes = columnBytes;
      _hydratedPoints = configuration.series.fold<int>(
        0,
        (total, series) => total + series.points.length,
      );
      _table = table;
      _status =
          'inlineColumns decoded, hydrated, and projected into '
          '${table.wideRows.length} exact-X table rows.';
    });
  }

  String? _encode(ChartArtifact artifact) {
    final result = ChartArtifactJsonCodec.encode(artifact);
    return switch (result) {
      ChartArtifactSuccess<String>() => result.value,
      ChartArtifactFailure<String>() => _recordEncodeFailure(result.error),
    };
  }

  String? _recordEncodeFailure(ChartArtifactError error) {
    _showError(error);
    return null;
  }

  void _showError(ChartArtifactError error) {
    setState(() {
      _error = true;
      _status = '${error.code}: ${error.message}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Payload Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _comparePayloads,
                    tooltip: 'Compare payloads',
                    icon: const Icon(Icons.view_column_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _comparePayloads,
                    icon: const Icon(Icons.view_column_outlined),
                    label: const Text('Compare payloads'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Same points, fewer repeated keys',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Columnar storage changes the wire shape, not the chart. '
                    'This lab compares encoded artifacts, decodes the columnar '
                    'one, hydrates it, and builds the native data table.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _PayloadStatus(status: _status, error: _error),
                const SizedBox(height: 24),
                _metrics(context),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chart = _panel(
                      context,
                      title: 'Mounted chart',
                      subtitle: '320 logical points across 2 series',
                      child: BravenChartPlus(
                        bravenChartController: _controller,
                        title: 'Training response',
                        subtitle: 'Payload comparison source',
                        showLegend: true,
                        series: _series(),
                      ),
                    );
                    final table = _panel(
                      context,
                      title: 'Decoded columnar table',
                      subtitle: 'Raw values preserved after JSON round-trip',
                      child: _table == null
                          ? const _PayloadPlaceholder()
                          : ChartDataTable(model: _table),
                    );
                    if (constraints.maxWidth < 980) {
                      return Column(
                        children: [chart, const SizedBox(height: 24), table],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: chart),
                        const SizedBox(width: 24),
                        Expanded(child: table),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metrics(BuildContext context) {
    final reduction = _pointBytes == null || _columnBytes == null
        ? null
        : ((_pointBytes! - _columnBytes!) / _pointBytes! * 100);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          label: 'Inline points',
          value: _pointBytes == null ? '—' : '${_pointBytes!} B',
        ),
        _MetricCard(
          label: 'Inline columns',
          value: _columnBytes == null ? '—' : '${_columnBytes!} B',
        ),
        _MetricCard(
          label: 'JSON reduction',
          value: reduction == null ? '—' : '${reduction.toStringAsFixed(1)}%',
        ),
        _MetricCard(
          label: 'Hydrated points',
          value: _hydratedPoints?.toString() ?? '—',
        ),
      ],
    );
  }

  Widget _panel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 420, child: child),
        ],
      ),
    ),
  );
}

class _PayloadStatus extends StatelessWidget {
  const _PayloadStatus({required this.status, required this.error});

  final String status;
  final bool error;

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
        child: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.view_column_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(status)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 168,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _PayloadPlaceholder extends StatelessWidget {
  const _PayloadPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.table_chart_outlined, size: 44),
        SizedBox(height: 12),
        Text('Run the comparison to build the table'),
      ],
    ),
  );
}

ChartArtifact _artifact(
  ChartDocumentSnapshot snapshot, {
  required DateTime capturedAt,
}) => ChartArtifact(
  artifactId: 'payload-lab-comparison',
  renderer: const ChartRendererInfo(package: 'braven_charts', version: '0.1.0'),
  createdAt: capturedAt,
  document: snapshot.document,
  viewState: snapshot.viewState,
);

List<ChartSeries> _series() => [
  LineChartSeries(
    id: 'power',
    name: 'Power',
    unit: 'W',
    color: const Color(0xFF2563EB),
    points: [
      for (var index = 0; index < 160; index++)
        ChartDataPoint(x: index.toDouble(), y: 220 + math.sin(index / 9) * 45),
    ],
  ),
  LineChartSeries(
    id: 'heart-rate',
    name: 'Heart rate',
    unit: 'bpm',
    color: const Color(0xFFDC2626),
    points: [
      for (var index = 0; index < 160; index++)
        ChartDataPoint(x: index.toDouble(), y: 128 + math.sin(index / 12) * 22),
    ],
  ),
];
