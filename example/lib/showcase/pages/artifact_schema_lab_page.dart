import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _CodecStatus { ready, success, failure }

/// Interactive schema-v1 codec surface.
///
/// This page deliberately tests the portable schema boundary only. Live chart
/// extraction and hydration are introduced by later implementation slices.
class ArtifactSchemaLabPage extends StatefulWidget {
  const ArtifactSchemaLabPage({super.key});

  @override
  State<ArtifactSchemaLabPage> createState() => _ArtifactSchemaLabPageState();
}

class _ArtifactSchemaLabPageState extends State<ArtifactSchemaLabPage> {
  final _jsonController = TextEditingController();
  final _jsonScrollController = ScrollController();

  _CodecStatus _status = _CodecStatus.ready;
  String _statusTitle = 'Sample ready';
  String _statusMessage = 'Edit the JSON or run the deterministic round trip.';
  ChartArtifact? _decodedArtifact;

  @override
  void initState() {
    super.initState();
    _resetSample();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _jsonScrollController.dispose();
    super.dispose();
  }

  void _resetSample() {
    final artifact = _buildSampleArtifact();
    final result = ChartArtifactJsonCodec.encode(artifact);
    final encoded = switch (result) {
      ChartArtifactSuccess<String>() => result.value,
      ChartArtifactFailure<String>() => '',
    };
    _jsonController.text = encoded;
    if (!mounted) return;
    setState(() {
      _decodedArtifact = artifact;
      _status = _CodecStatus.ready;
      _statusTitle = 'Sample ready';
      _statusMessage =
          'A built-in line model was encoded into a schema 1 document. '
          'No live chart extraction is used yet.';
    });
  }

  void _loadInvalidSchema() {
    _jsonController.text = _jsonController.text.replaceFirst(
      '"schemaVersion":1',
      '"schemaVersion":99',
    );
    setState(() {
      _status = _CodecStatus.ready;
      _statusTitle = 'Future schema loaded';
      _statusMessage =
          'Run the round trip to inspect the structured compatibility failure.';
    });
  }

  void _roundTrip() {
    final decoded = ChartArtifactJsonCodec.decode(
      _jsonController.text,
      supportedCapabilities: const {'series.line'},
    );
    switch (decoded) {
      case ChartArtifactSuccess<ChartArtifactDecodeResult>():
        final artifact = decoded.value.artifact;
        for (final document in artifact.document.series) {
          final model = ChartSeriesDocumentCodec.decode(document);
          if (model case ChartArtifactFailure<ChartSeries>()) {
            _showFailure(model.error);
            return;
          }
        }
        final encoded = ChartArtifactJsonCodec.encode(artifact);
        switch (encoded) {
          case ChartArtifactSuccess<String>():
            _jsonController.text = encoded.value;
            setState(() {
              _decodedArtifact = artifact;
              _status = _CodecStatus.success;
              _statusTitle = 'Round trip passed';
              _statusMessage =
                  'Decoded schema ${decoded.value.sourceSchemaVersion}, '
                  'rehydrated the built-in series model, validated '
                  'capabilities, and produced canonical JSON.';
            });
          case ChartArtifactFailure<String>():
            _showFailure(encoded.error);
        }
      case ChartArtifactFailure<ChartArtifactDecodeResult>():
        _showFailure(decoded.error);
    }
  }

  void _showFailure(ChartArtifactError error) {
    setState(() {
      _status = _CodecStatus.failure;
      _statusTitle = error.code;
      _statusMessage = [
        error.message,
        if (error.path != null) 'Path: ${error.path}',
      ].join(' ');
    });
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: _jsonController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Canonical JSON copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifact = _decodedArtifact;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artifact schema lab',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test the built-in series model codec, schema-v1 JSON '
                'envelope, deterministic encoding, capability validation, '
                'and structured failures. Live chart capture and widget '
                'rehydration are not implemented on this surface yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _StatusBanner(
                status: _status,
                title: _statusTitle,
                message: _statusMessage,
              ),
              const SizedBox(height: 32),
              _ArtifactSummary(artifact: artifact),
              const SizedBox(height: 32),
              Text(
                'Canonical JSON',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Edit the payload to exercise validation. Successful round '
                'trips replace it with canonical key and number ordering.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _roundTrip,
                    icon: const Icon(Icons.sync),
                    label: const Text('Round-trip JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetSample,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset sample'),
                  ),
                  TextButton.icon(
                    onPressed: _loadInvalidSchema,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Load invalid schema'),
                  ),
                  TextButton.icon(
                    onPressed: _copyJson,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy JSON'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Editable chart artifact JSON',
                textField: true,
                child: Container(
                  height: 440,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Scrollbar(
                    controller: _jsonScrollController,
                    thumbVisibility: true,
                    child: TextField(
                      controller: _jsonController,
                      scrollController: _jsonScrollController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.title,
    required this.message,
  });

  final _CodecStatus status;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, foreground, background) = switch (status) {
      _CodecStatus.ready => (
        Icons.info_outline,
        colors.onSecondaryContainer,
        colors.secondaryContainer,
      ),
      _CodecStatus.success => (
        Icons.check_circle_outline,
        colors.onTertiaryContainer,
        colors.tertiaryContainer,
      ),
      _CodecStatus.failure => (
        Icons.error_outline,
        colors.onErrorContainer,
        colors.errorContainer,
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtifactSummary extends StatelessWidget {
  const _ArtifactSummary({required this.artifact});

  final ChartArtifact? artifact;

  @override
  Widget build(BuildContext context) {
    final document = artifact?.document;
    final values = [
      ('Schema', artifact?.schemaVersion.toString() ?? '—'),
      ('Series', document?.series.length.toString() ?? '—'),
      ('Points', document?.pointCount.toString() ?? '—'),
      ('Revision', document?.revision.toString() ?? '—'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final (label, value) in values)
          SizedBox(
            width: 176,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

ChartArtifact _buildSampleArtifact() {
  final seriesResult = ChartSeriesDocumentCodec.encode(
    LineChartSeries(
      id: 'power',
      name: 'Power',
      unit: 'W',
      yAxisId: 'power-axis',
      color: const Color(0xFF2F6EA5),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 3,
      showDataPointMarkers: true,
      points: [
        for (final (index, y) in const [
          (0.0, 186.0),
          (1.0, 224.0),
          (2.0, 208.0),
          (3.0, 252.0),
        ])
          ChartDataPoint(x: index, y: y, label: '${y.toInt()} W'),
      ],
    ),
  );
  final seriesDocument = switch (seriesResult) {
    ChartArtifactSuccess<ChartSeriesDocument>() => seriesResult.value,
    ChartArtifactFailure<ChartSeriesDocument>() => throw StateError(
      seriesResult.error.message,
    ),
  };
  return ChartArtifact(
    artifactId: 'showcase-artifact-v1',
    renderer: const ChartRendererInfo(
      package: 'braven_charts',
      version: '0.1.0',
    ),
    createdAt: DateTime.utc(2026, 7, 14, 8, 30),
    document: ChartDocument(
      documentId: 'showcase-power-series',
      revision: 1,
      title: 'Power profile',
      series: [seriesDocument],
      xAxis: ChartAxisDocument(
        id: 'elapsed',
        position: 'bottom',
        label: 'Elapsed time',
        unit: 'min',
      ),
      axes: [
        ChartAxisDocument(
          id: 'power-axis',
          position: 'left',
          label: 'Power',
          unit: 'W',
        ),
      ],
      theme: ChartThemeDocument(reference: 'braven.light'),
      interaction: ChartInteractionDocument(
        configuration:
            JsonValue.fromJson({'zoom': true, 'pan': true}) as JsonObjectValue,
      ),
    ),
    viewState: ChartViewState(visibleAxisIds: const ['power-axis']),
    extensions: const {'showcase.stage': JsonStringValue('schema-foundation')},
  );
}
