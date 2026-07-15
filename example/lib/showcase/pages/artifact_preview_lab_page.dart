import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Live proof of revision-bound PNG capture and independent failure handling.
class ArtifactPreviewLabPage extends StatefulWidget {
  const ArtifactPreviewLabPage({super.key});

  @override
  State<ArtifactPreviewLabPage> createState() => _ArtifactPreviewLabPageState();
}

class _ArtifactPreviewLabPageState extends State<ArtifactPreviewLabPage> {
  final _controller = BravenChartController();
  Uint8List? _previewBytes;
  String? _documentHash;
  String _status = 'Capture a PNG preview from the mounted chart.';
  int? _widthPixels;
  int? _heightPixels;
  bool _busy = false;
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capturePreview() async {
    setState(() {
      _busy = true;
      _error = false;
      _status = 'Capturing a stable frame…';
    });
    final result = await _controller.capturePreview(
      const ChartPreviewOptions(
        pixelRatio: 1.5,
        documentOptions: ChartDocumentExtractOptions(documentId: 'preview-lab'),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case ChartArtifactSuccess<ChartPreview>():
        setState(() {
          _busy = false;
          _previewBytes = result.value.bytes;
          _documentHash = result.value.documentHash;
          _widthPixels = result.value.widthPixels;
          _heightPixels = result.value.heightPixels;
          _status = 'PNG captured from the same immutable document revision.';
        });
      case ChartArtifactFailure<ChartPreview>():
        setState(() {
          _busy = false;
          _error = true;
          _status = '${result.error.code}: ${result.error.message}';
        });
    }
  }

  Future<void> _proveIndependentFailure() async {
    setState(() {
      _busy = true;
      _error = false;
      _status = 'Applying an intentionally tiny preview pixel limit…';
    });
    final preview = await _controller.capturePreview(
      const ChartPreviewOptions(maxPixelCount: 1),
    );
    final document = _controller.extractDocument(
      const ChartDocumentExtractOptions(documentId: 'preview-lab'),
    );
    if (!mounted) return;
    final previewCode = switch (preview) {
      ChartArtifactFailure<ChartPreview>() => preview.error.code,
      ChartArtifactSuccess<ChartPreview>() => 'unexpected_success',
    };
    final revision = switch (document) {
      ChartArtifactSuccess<ChartDocumentSnapshot>() =>
        document.value.document.revision,
      ChartArtifactFailure<ChartDocumentSnapshot>() => null,
    };
    setState(() {
      _busy = false;
      _error = false;
      _status =
          '$previewCode returned; native document revision $revision remains usable.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Preview Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _busy ? null : _capturePreview,
                    tooltip: 'Capture PNG preview',
                    icon: const Icon(Icons.photo_camera_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _busy ? null : _capturePreview,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Capture PNG preview'),
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
                  'Native document first, preview second',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The PNG is captured from a stable repaint boundary and tied '
                  'to the canonical SHA-256 document hash. Preview failures do '
                  'not invalidate the chart document.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _PreviewStatus(
                  status: _status,
                  busy: _busy,
                  error: _error,
                  dimensions: _widthPixels == null
                      ? null
                      : '$_widthPixels×$_heightPixels px',
                  hash: _documentHash,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final source = _panel(
                      context,
                      eyebrow: 'SOURCE',
                      title: 'Mounted interactive chart',
                      child: _chart(),
                    );
                    final preview = _panel(
                      context,
                      eyebrow: 'PREVIEW',
                      title: 'Revision-bound PNG',
                      child: _previewBytes == null
                          ? const _PreviewPlaceholder()
                          : ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                              child: Center(
                                child: Image.memory(
                                  _previewBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  semanticLabel: 'Captured chart preview',
                                ),
                              ),
                            ),
                    );
                    if (constraints.maxWidth < 980) {
                      return Column(
                        children: [source, const SizedBox(height: 20), preview],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: source),
                        const SizedBox(width: 20),
                        Expanded(child: preview),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _proveIndependentFailure,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Test independent failure'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chart() => BravenChartPlus(
    bravenChartController: _controller,
    title: 'Training load',
    subtitle: 'Portable preview source',
    showLegend: false,
    series: const [
      LineChartSeries(
        id: 'load',
        name: 'Load',
        color: Color(0xFF2563EB),
        points: [
          ChartDataPoint(x: 1, y: 42),
          ChartDataPoint(x: 2, y: 58),
          ChartDataPoint(x: 3, y: 51),
          ChartDataPoint(x: 4, y: 70),
          ChartDataPoint(x: 5, y: 76),
        ],
      ),
    ],
  );

  Widget _panel(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required Widget child,
  }) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(height: 380, child: child),
        ],
      ),
    ),
  );
}

class _PreviewStatus extends StatelessWidget {
  const _PreviewStatus({
    required this.status,
    required this.busy,
    required this.error,
    this.dimensions,
    this.hash,
  });

  final String status;
  final bool busy;
  final bool error;
  final String? dimensions;
  final String? hash;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    error ? Icons.error_outline : Icons.check_circle_outline,
                  ),
                const SizedBox(width: 12),
                Expanded(child: Text(status)),
                if (dimensions != null) Chip(label: Text(dimensions!)),
              ],
            ),
            if (hash != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                hash!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 44),
          SizedBox(height: 12),
          Text('No preview captured yet'),
        ],
      ),
    ),
  );
}
