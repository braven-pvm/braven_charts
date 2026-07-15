import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Interactive checkpoint for binary-v1 payload size, integrity, and reuse.
class ArtifactBinaryPayloadLabPage extends StatefulWidget {
  const ArtifactBinaryPayloadLabPage({super.key});

  @override
  State<ArtifactBinaryPayloadLabPage> createState() =>
      _ArtifactBinaryPayloadLabPageState();
}

class _ArtifactBinaryPayloadLabPageState
    extends State<ArtifactBinaryPayloadLabPage> {
  static const _datasetSizes = [250, 2500, 25000];

  int _pointCount = _datasetSizes.first;
  _BinaryLabState _state = _BinaryLabState.idle;
  String _status =
      'Choose a dataset, then encode, resolve, verify, and hydrate it.';
  String? _errorCode;
  _BinaryMetrics? _metrics;
  HydratedChartConfiguration? _configuration;
  ChartTableModel? _table;

  Future<void> _run({required bool corruptBytes}) async {
    setState(() {
      _state = _BinaryLabState.running;
      _status = corruptBytes
          ? 'Changing one stored byte to prove integrity fails closed.'
          : 'Encoding exact numeric columns into binary-v1.';
      _errorCode = null;
      _metrics = null;
      _configuration = null;
      _table = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final payload = _payload(_pointCount);
    final jsonWatch = Stopwatch()..start();
    final jsonResult = ChartDataBlobCodec.encode(payload);
    jsonWatch.stop();
    if (jsonResult case ChartArtifactFailure<ChartDataBlob>()) {
      _showFailure(jsonResult.error);
      return;
    }

    final binaryWatch = Stopwatch()..start();
    final binaryResult = ChartDataBinaryCodec.encode(payload);
    binaryWatch.stop();
    if (binaryResult case ChartArtifactFailure<ChartDataBlob>()) {
      _showFailure(binaryResult.error);
      return;
    }
    final jsonBlob = (jsonResult as ChartArtifactSuccess<ChartDataBlob>).value;
    final binaryBlob =
        (binaryResult as ChartArtifactSuccess<ChartDataBlob>).value;
    final reference = binaryBlob.reference(
      resolverKey: 'binary-lab/$_pointCount',
    );
    final storedBytes = [...binaryBlob.bytes];
    if (corruptBytes) {
      storedBytes[storedBytes.length ~/ 2] ^= 0x01;
    }
    final artifactResult = _artifact(reference, Theme.of(context).brightness);
    if (artifactResult case ChartArtifactFailure<ChartArtifact>()) {
      _showFailure(artifactResult.error);
      return;
    }

    final resolveWatch = Stopwatch()..start();
    final resolved = await ChartDataResolution.resolveArtifact(
      (artifactResult as ChartArtifactSuccess<ChartArtifact>).value,
      resolver: _BinaryLabResolver(storedBytes),
    );
    if (!mounted) return;
    if (resolved case ChartArtifactFailure<ChartArtifact>()) {
      resolveWatch.stop();
      setState(() {
        _metrics = _BinaryMetrics(
          pointCount: _pointCount,
          jsonBytes: jsonBlob.byteLength,
          binaryBytes: binaryBlob.byteLength,
          encodeDuration: binaryWatch.elapsed,
          resolveDuration: resolveWatch.elapsed,
          checksum: reference.checksum,
        );
      });
      _showFailure(resolved.error);
      return;
    }
    final resolvedArtifact =
        (resolved as ChartArtifactSuccess<ChartArtifact>).value;
    final hydrated = ChartDocumentHydrator.hydrateArtifact(resolvedArtifact);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      resolveWatch.stop();
      _showFailure(hydrated.error);
      return;
    }
    final table = ChartTableModel.fromDocument(resolvedArtifact.document);
    resolveWatch.stop();

    setState(() {
      _state = _BinaryLabState.success;
      _configuration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
      _table = table;
      _metrics = _BinaryMetrics(
        pointCount: _pointCount,
        jsonBytes: jsonBlob.byteLength,
        binaryBytes: binaryBlob.byteLength,
        encodeDuration: binaryWatch.elapsed,
        resolveDuration: resolveWatch.elapsed,
        checksum: reference.checksum,
      );
      _status =
          'Verified binary payload. Every point is available to the normal '
          'chart and table consumers.';
    });
  }

  ChartArtifactResult<ChartArtifact> _artifact(
    ReferencedPayload payload,
    Brightness brightness,
  ) {
    final series = ChartSeriesDocumentCodec.encode(
      const LineChartSeries(
        id: 'power',
        name: 'Power',
        unit: 'W',
        color: Color(0xFF2563EB),
        points: [ChartDataPoint(x: 0, y: 220)],
      ),
    );
    if (series case ChartArtifactFailure<ChartSeriesDocument>()) {
      return ChartArtifactFailure(error: series.error);
    }
    final seriesJson = (series as ChartArtifactSuccess<ChartSeriesDocument>)
        .value
        .toJson();
    seriesJson['data'] = payload.toJson();
    final theme = ChartThemeDocumentCodec.encode(
      brightness == Brightness.dark ? ChartTheme.dark : ChartTheme.light,
    );
    if (theme case ChartArtifactFailure<ChartThemeDocument>()) {
      return ChartArtifactFailure(error: theme.error);
    }
    final interaction = ChartInteractionDocumentCodec.encode(
      const InteractionConfig(),
    );
    if (interaction case ChartArtifactFailure<ChartInteractionDocument>()) {
      return ChartArtifactFailure(error: interaction.error);
    }
    return ChartArtifactSuccess(
      value: ChartArtifact(
        artifactId: 'binary-payload-lab-artifact',
        renderer: const ChartRendererInfo(
          package: 'braven_charts',
          version: '0.1.0',
        ),
        createdAt: DateTime.utc(2026, 7, 15, 10),
        document: ChartDocument(
          documentId: 'binary-payload-lab',
          revision: 1,
          series: [ChartSeriesDocument.fromJson(seriesJson)],
          xAxis: ChartAxisDocument(id: 'sample', position: 'bottom'),
          axes: const [],
          theme: (theme as ChartArtifactSuccess<ChartThemeDocument>).value,
          interaction:
              (interaction as ChartArtifactSuccess<ChartInteractionDocument>)
                  .value,
        ),
      ),
    );
  }

  void _showFailure(ChartArtifactError error) {
    if (!mounted) return;
    setState(() {
      _state = _BinaryLabState.error;
      _errorCode = error.code;
      _status = '${error.message} The payload was not hydrated.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final running = _state == _BinaryLabState.running;
    return Scaffold(
      appBar: AppBar(title: const Text('Binary Payload Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compress chart data without losing a point',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Text(
                    'Binary-v1 preserves exact IEEE-754 values, keeps optional '
                    'columns portable, and still passes through the same '
                    'host resolver and SHA-256 integrity gates.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Dataset size', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: [
                    for (final value in _datasetSizes)
                      ButtonSegment(
                        value: value,
                        label: Text(_formatCount(value)),
                      ),
                  ],
                  selected: {_pointCount},
                  onSelectionChanged: running
                      ? null
                      : (selection) =>
                            setState(() => _pointCount = selection.single),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: running
                            ? null
                            : () => _run(corruptBytes: false),
                        icon: const Icon(Icons.compress_outlined),
                        label: const Text('Run binary round trip'),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: running
                            ? null
                            : () => _run(corruptBytes: true),
                        icon: const Icon(Icons.gpp_bad_outlined),
                        label: const Text('Test corrupt bytes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _StatusBanner(
                  state: _state,
                  status: _status,
                  errorCode: _errorCode,
                ),
                const SizedBox(height: 24),
                _MetricsGrid(metrics: _metrics),
                const SizedBox(height: 24),
                _FormatCard(checksum: _metrics?.checksum),
                const SizedBox(height: 24),
                _buildResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_state == _BinaryLabState.success) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final chart = _ResultCard(
            title: 'Hydrated chart',
            subtitle: 'Fresh runtime state from verified binary data',
            child: _configuration!.build(),
          );
          final table = _ResultCard(
            title: 'Resolved data table',
            subtitle: 'The same exact points through the native table model',
            child: ChartDataTable(model: _table),
          );
          if (constraints.maxWidth < 980) {
            return Column(children: [chart, const SizedBox(height: 24), table]);
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
      );
    }
    return _ResultCard(
      title: _state == _BinaryLabState.error
          ? 'Hydration blocked safely'
          : 'Round-trip preview',
      subtitle: _state == _BinaryLabState.error
          ? 'Unverified bytes never reach chart or table consumers'
          : 'Run the codec to inspect the hydrated result',
      child: Center(
        child: _state == _BinaryLabState.running
            ? const CircularProgressIndicator()
            : Icon(
                _state == _BinaryLabState.error
                    ? Icons.gpp_bad_outlined
                    : Icons.data_array_outlined,
                size: 56,
              ),
      ),
    );
  }
}

enum _BinaryLabState { idle, running, success, error }

class _BinaryMetrics {
  const _BinaryMetrics({
    required this.pointCount,
    required this.jsonBytes,
    required this.binaryBytes,
    required this.encodeDuration,
    required this.resolveDuration,
    required this.checksum,
  });

  final int pointCount;
  final int jsonBytes;
  final int binaryBytes;
  final Duration encodeDuration;
  final Duration resolveDuration;
  final String checksum;

  double get saving => 1 - binaryBytes / jsonBytes;
}

class _BinaryLabResolver implements ChartDataResolver {
  const _BinaryLabResolver(this.bytes);

  final List<int> bytes;

  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async => ChartArtifactSuccess(value: bytes);
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.state,
    required this.status,
    required this.errorCode,
  });

  final _BinaryLabState state;
  final String status;
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = state == _BinaryLabState.error;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(error ? Icons.error_outline : Icons.verified_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorCode != null) ...[
                    Text(
                      errorCode!,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final _BinaryMetrics? metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? 6
          : constraints.maxWidth >= 700
          ? 3
          : 2;
      final items = [
        ('Points', metrics == null ? '—' : _formatCount(metrics!.pointCount)),
        ('JSON size', metrics == null ? '—' : _formatBytes(metrics!.jsonBytes)),
        (
          'Binary size',
          metrics == null ? '—' : _formatBytes(metrics!.binaryBytes),
        ),
        (
          'Space saved',
          metrics == null
              ? '—'
              : '${(metrics!.saving * 100).toStringAsFixed(1)}%',
        ),
        (
          'Encode time',
          metrics == null ? '—' : _formatDuration(metrics!.encodeDuration),
        ),
        (
          'Resolve + hydrate',
          metrics == null ? '—' : _formatDuration(metrics!.resolveDuration),
        ),
      ];
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 6
            ? 1.35
            : columns == 3
            ? 1.7
            : 1.2,
        children: [
          for (final item in items) _MetricCard(label: item.$1, value: item.$2),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({required this.checksum});

  final String? checksum;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Binary-v1 contract',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Stable format metadata carried by the reference manifest',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const _KeyValue(
            label: 'Content type',
            value: ChartDataBinaryCodec.contentType,
          ),
          const _KeyValue(
            label: 'Format version',
            value: '${ChartDataBinaryCodec.formatVersion}',
          ),
          const _KeyValue(
            label: 'Compression',
            value: ChartDataBinaryCodec.compression,
          ),
          _KeyValue(
            label: 'SHA-256',
            value: checksum ?? 'Created after encoding',
          ),
        ],
      ),
    ),
  );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(value),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 128,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(width: 16),
            Expanded(child: SelectableText(value)),
          ],
        );
      },
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
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

InlineColumnarPayload _payload(int pointCount) => InlineColumnarPayload(
  xValues: [
    for (var index = 0; index < pointCount; index++)
      ChartNumberDocument.fromDouble(index.toDouble()),
  ],
  yValues: [
    for (var index = 0; index < pointCount; index++)
      ChartNumberDocument.fromDouble(
        220 + math.sin(index / 24) * 42 + index * 0.002,
      ),
  ],
);

String _formatCount(int value) {
  if (value >= 1000) {
    final thousands = value / 1000;
    return '${thousands.toStringAsFixed(thousands == thousands.round() ? 0 : 1)}K';
  }
  return '$value';
}

String _formatBytes(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '$value B';
}

String _formatDuration(Duration value) {
  final milliseconds = value.inMicroseconds / 1000;
  return '${milliseconds.toStringAsFixed(milliseconds < 10 ? 2 : 1)} ms';
}
