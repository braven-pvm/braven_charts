import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Interactive proof of atomic artifact composition and preview fallback.
class ArtifactExportLabPage extends StatefulWidget {
  const ArtifactExportLabPage({super.key});

  @override
  State<ArtifactExportLabPage> createState() => _ArtifactExportLabPageState();
}

class _ArtifactExportLabPageState extends State<ArtifactExportLabPage> {
  final _controller = BravenChartController();
  ChartArtifact? _artifact;
  List<ChartArtifactWarning> _warnings = const [];
  String _status = 'Extract the mounted chart into one portable artifact.';
  bool _busy = false;
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extract({bool forcePreviewFailure = false}) async {
    setState(() {
      _busy = true;
      _error = false;
      _status = forcePreviewFailure
          ? 'Testing document preservation during preview failure…'
          : 'Capturing an atomic document and preview…';
    });
    final result = await _controller.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: forcePreviewFailure
            ? 'showcase-preview-fallback'
            : 'showcase-portable-artifact',
        includePreview: true,
        documentOptions: const ChartDocumentExtractOptions(
          documentId: 'showcase-export-document',
        ),
        previewOptions: ChartPreviewOptions(
          pixelRatio: 1.5,
          maxPixelCount: forcePreviewFailure ? 1 : 64 * 1024 * 1024,
        ),
        provenance: ChartArtifactProvenance(
          values: JsonObjectValue(const {
            'surface': JsonStringValue('artifact-export-lab'),
          }),
        ),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case ChartArtifactSuccess<ChartArtifact>():
        setState(() {
          _busy = false;
          _artifact = result.value;
          _warnings = result.warnings;
          _status = result.value.preview == null
              ? 'Native artifact preserved; preview omitted with a warning.'
              : 'Portable artifact and hash-matched preview captured.';
        });
      case ChartArtifactFailure<ChartArtifact>():
        setState(() {
          _busy = false;
          _error = true;
          _warnings = result.warnings;
          _status = '${result.error.code}: ${result.error.message}';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Export Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _busy ? null : _extract,
                    tooltip: 'Extract artifact',
                    icon: const Icon(Icons.inventory_2_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _busy ? null : _extract,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Extract artifact'),
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
                  'One document, one matching preview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The controller returns a portable envelope only when the '
                  'preview hash matches the final document. Raster failure '
                  'degrades to a warning and keeps the native artifact.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _ExportStatus(
                  status: _status,
                  busy: _busy,
                  error: _error,
                  warningCount: _warnings.length,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chart = _chartPanel(context);
                    final inspector = _artifactPanel(context);
                    if (constraints.maxWidth < 980) {
                      return Column(
                        children: [
                          chart,
                          const SizedBox(height: 20),
                          inspector,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: chart),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: inspector),
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

  Widget _chartPanel(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mounted source', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'The interactive chart remains the runtime source.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: BravenChartPlus(
              bravenChartController: _controller,
              title: 'Training response',
              subtitle: 'Atomic export source',
              showLegend: true,
              series: const [
                LineChartSeries(
                  id: 'power',
                  name: 'Power',
                  unit: 'W',
                  color: Color(0xFF2563EB),
                  points: [
                    ChartDataPoint(x: 1, y: 205),
                    ChartDataPoint(x: 2, y: 232),
                    ChartDataPoint(x: 3, y: 248),
                    ChartDataPoint(x: 4, y: 271),
                    ChartDataPoint(x: 5, y: 255),
                    ChartDataPoint(x: 6, y: 282),
                  ],
                ),
                LineChartSeries(
                  id: 'heart-rate',
                  name: 'Heart rate',
                  unit: 'bpm',
                  color: Color(0xFFDC2626),
                  points: [
                    ChartDataPoint(x: 1, y: 124),
                    ChartDataPoint(x: 2, y: 132),
                    ChartDataPoint(x: 3, y: 138),
                    ChartDataPoint(x: 4, y: 149),
                    ChartDataPoint(x: 5, y: 153),
                    ChartDataPoint(x: 6, y: 158),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _artifactPanel(BuildContext context) {
    final artifact = _artifact;
    final previewBytes = artifact?.preview?.bytes;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portable result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (artifact == null)
              const _ArtifactPlaceholder()
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Revision ${artifact.document.revision}')),
                  Chip(label: Text('${artifact.document.pointCount} points')),
                  Chip(
                    avatar: Icon(
                      artifact.preview == null
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      size: 18,
                    ),
                    label: Text(
                      artifact.preview == null ? 'Document only' : 'Hash match',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PreviewResult(bytes: previewBytes),
              const SizedBox(height: 16),
              SelectableText(
                artifact.artifactId,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              SelectableText(
                artifact.preview?.documentHash ??
                    ChartArtifactCanonicalizer.documentHash(artifact.document),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
              if (_warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final warning in _warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${warning.code}: ${warning.message}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _extract(forcePreviewFailure: true),
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Test preview fallback'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportStatus extends StatelessWidget {
  const _ExportStatus({
    required this.status,
    required this.busy,
    required this.error,
    required this.warningCount,
  });

  final String status;
  final bool busy;
  final bool error;
  final int warningCount;

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
            if (busy)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(error ? Icons.error_outline : Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(status)),
            if (warningCount > 0) Chip(label: Text('$warningCount warning')),
          ],
        ),
      ),
    );
  }
}

class _PreviewResult extends StatelessWidget {
  const _PreviewResult({this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    width: double.infinity,
    child: bytes == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No preview in this artifact')),
          )
        : Image.memory(
            bytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            semanticLabel: 'Artifact preview',
          ),
  );
}

class _ArtifactPlaceholder extends StatelessWidget {
  const _ArtifactPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text('No artifact extracted yet'),
  );
}
