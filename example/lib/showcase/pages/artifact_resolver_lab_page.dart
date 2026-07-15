import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Host-bound external payload resolution with visible integrity checkpoints.
class ArtifactResolverLabPage extends StatefulWidget {
  const ArtifactResolverLabPage({super.key});

  @override
  State<ArtifactResolverLabPage> createState() =>
      _ArtifactResolverLabPageState();
}

class _ArtifactResolverLabPageState extends State<ArtifactResolverLabPage> {
  final _controller = BravenChartController();
  _ResolverState _state = _ResolverState.idle;
  String _status =
      'Create a referenced artifact, then resolve it through a host boundary.';
  String? _errorCode;
  List<ReferencedPayload> _references = const [];
  HydratedChartConfiguration? _configuration;
  ChartTableModel? _table;
  int _resolverCalls = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run({required bool tamperChecksum}) async {
    setState(() {
      _state = _ResolverState.resolving;
      _status = tamperChecksum
          ? 'Resolving altered content to prove the checksum gate fails closed.'
          : 'Resolving host-owned blobs and verifying their manifests.';
      _errorCode = null;
      _configuration = null;
      _table = null;
      _resolverCalls = 0;
    });

    final extracted = _controller.extractDocument(
      const ChartDocumentExtractOptions(
        documentId: 'resolver-lab',
        dataStorage: ChartDataStorage.inlineColumns,
      ),
    );
    if (extracted case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      _showFailure(extracted.error);
      return;
    }

    final snapshot =
        (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
    final prepared = _externalize(snapshot, tamperChecksum: tamperChecksum);
    if (prepared case ChartArtifactFailure<_PreparedArtifact>()) {
      _showFailure(prepared.error);
      return;
    }
    final value = (prepared as ChartArtifactSuccess<_PreparedArtifact>).value;
    if (mounted) setState(() => _references = value.references);

    final resolver = _LabResolver(value.blobs);
    final resolved = await ChartDataResolution.resolveArtifact(
      value.artifact,
      resolver: resolver,
    );
    if (!mounted) return;
    _resolverCalls = resolver.calls;
    if (resolved case ChartArtifactFailure<ChartArtifact>()) {
      _showFailure(resolved.error);
      return;
    }

    final resolvedArtifact =
        (resolved as ChartArtifactSuccess<ChartArtifact>).value;
    final hydrated = ChartDocumentHydrator.hydrateArtifact(resolvedArtifact);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      _showFailure(hydrated.error);
      return;
    }

    setState(() {
      _state = _ResolverState.success;
      _configuration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
      _table = ChartTableModel.fromDocument(
        resolvedArtifact.document,
        viewState: resolvedArtifact.viewState,
      );
      _status =
          '${value.references.length} referenced payloads resolved, verified, '
          'hydrated, and projected into the native table.';
    });
  }

  ChartArtifactResult<_PreparedArtifact> _externalize(
    ChartDocumentSnapshot snapshot, {
    required bool tamperChecksum,
  }) {
    final documentJson = snapshot.document.toJson();
    final series = documentJson['series']! as List<Object?>;
    final references = <ReferencedPayload>[];
    final blobs = <String, List<int>>{};

    for (var index = 0; index < series.length; index++) {
      final seriesJson = series[index]! as Map<String, Object?>;
      final payload = ChartDataPayload.fromJson(
        seriesJson['data']! as Map<String, Object?>,
      );
      if (payload is! InlineChartDataPayload) {
        return ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.unsupportedModelType,
            message: 'Resolver Lab source data must be inline.',
          ),
        );
      }
      final encoded = ChartDataBlobCodec.encode(payload);
      if (encoded case ChartArtifactFailure<ChartDataBlob>()) {
        return ChartArtifactFailure(error: encoded.error);
      }
      final blob = (encoded as ChartArtifactSuccess<ChartDataBlob>).value;
      final key = 'resolver-lab/${seriesJson['id']}';
      var reference = blob.reference(resolverKey: key);
      if (tamperChecksum && index == 0) {
        reference = ReferencedPayload(
          contentType: reference.contentType,
          byteLength: reference.byteLength,
          checksum: _differentChecksum(reference.checksum),
          pointCount: reference.pointCount,
          resolverKey: key,
        );
      }
      blobs[key] = blob.bytes;
      references.add(reference);
      seriesJson['data'] = reference.toJson();
    }

    final document = ChartDocument.fromJson(documentJson);
    return ChartArtifactSuccess(
      value: _PreparedArtifact(
        artifact: ChartArtifact(
          artifactId: 'resolver-lab-artifact',
          renderer: const ChartRendererInfo(
            package: 'braven_charts',
            version: '0.1.0',
          ),
          createdAt: DateTime.utc(2026, 7, 15, 8),
          document: document,
          viewState: snapshot.viewState,
        ),
        references: references,
        blobs: blobs,
      ),
    );
  }

  void _showFailure(ChartArtifactError error) {
    if (!mounted) return;
    setState(() {
      _state = _ResolverState.error;
      _errorCode = error.code;
      _status = '${error.message} Fix the manifest or host resolver and retry.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Resolver Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'External data, host-controlled',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'The artifact keeps a small manifest. The host authorizes '
                    'storage access; the package verifies size, SHA-256, and '
                    'point count before hydration.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _state == _ResolverState.resolving
                            ? null
                            : () => _run(tamperChecksum: false),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Resolve payload'),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _state == _ResolverState.resolving
                            ? null
                            : () => _run(tamperChecksum: true),
                        icon: const Icon(Icons.policy_outlined),
                        label: const Text('Test checksum failure'),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final manifest = _ManifestPanel(
                      references: _references,
                      resolverCalls: _resolverCalls,
                    );
                    final pipeline = _PipelinePanel(
                      completedSteps: _completedSteps,
                      state: _state,
                    );
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          manifest,
                          const SizedBox(height: 24),
                          pipeline,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: manifest),
                        const SizedBox(width: 24),
                        Expanded(child: pipeline),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _Panel(
                  title: 'Live source chart',
                  subtitle: 'Effective data captured before externalization',
                  child: BravenChartPlus(
                    bravenChartController: _controller,
                    title: 'Training response',
                    subtitle: 'Resolver Lab source',
                    showLegend: true,
                    series: _sourceSeries(),
                  ),
                ),
                const SizedBox(height: 24),
                _resultPanel(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _completedSteps => switch (_state) {
    _ResolverState.idle => 0,
    _ResolverState.resolving => 1,
    _ResolverState.success => 4,
    _ResolverState.error =>
      _errorCode == ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch
          ? 2
          : 1,
  };

  Widget _resultPanel(BuildContext context) {
    if (_state == _ResolverState.success) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final chart = _Panel(
            title: 'Hydrated chart',
            subtitle: 'Fresh runtime state from verified external data',
            child: _configuration!.build(),
          );
          final table = _Panel(
            title: 'Resolved data table',
            subtitle: 'Raw values from the same resolved document',
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
    return _Panel(
      title: _state == _ResolverState.error
          ? 'Hydration blocked safely'
          : 'Resolved artifact preview',
      subtitle: _state == _ResolverState.error
          ? 'Unverified bytes never reach the chart or table'
          : 'Run the authorized resolver to build the chart and table',
      child: Center(
        child: _state == _ResolverState.resolving
            ? const CircularProgressIndicator()
            : Icon(
                _state == _ResolverState.error
                    ? Icons.gpp_bad_outlined
                    : Icons.storage_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

enum _ResolverState { idle, resolving, success, error }

class _PreparedArtifact {
  const _PreparedArtifact({
    required this.artifact,
    required this.references,
    required this.blobs,
  });

  final ChartArtifact artifact;
  final List<ReferencedPayload> references;
  final Map<String, List<int>> blobs;
}

class _LabResolver implements ChartDataResolver {
  _LabResolver(this.blobs);

  final Map<String, List<int>> blobs;
  int calls = 0;

  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final bytes = blobs[reference.resolverKey];
    if (bytes == null) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: 'host_data_access_denied',
          message: 'The host did not authorize this resolver key.',
        ),
      );
    }
    return ChartArtifactSuccess(value: bytes);
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.state,
    required this.status,
    required this.errorCode,
  });

  final _ResolverState state;
  final String status;
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = state == _ResolverState.error;
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
            Icon(error ? Icons.error_outline : Icons.verified_user_outlined),
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

class _ManifestPanel extends StatelessWidget {
  const _ManifestPanel({required this.references, required this.resolverCalls});

  final List<ReferencedPayload> references;
  final int resolverCalls;

  @override
  Widget build(BuildContext context) {
    final totalBytes = references.fold<int>(
      0,
      (sum, ref) => sum + ref.byteLength,
    );
    final totalPoints = references.fold<int>(
      0,
      (sum, ref) => sum + ref.pointCount,
    );
    return _InfoCard(
      title: 'Reference manifest',
      subtitle: 'Portable metadata only — no storage credentials',
      children: [
        _KeyValue(label: 'Payloads', value: '${references.length}'),
        _KeyValue(label: 'Declared bytes', value: '$totalBytes'),
        _KeyValue(label: 'Declared points', value: '$totalPoints'),
        _KeyValue(label: 'Resolver calls', value: '$resolverCalls'),
        if (references.isNotEmpty) ...[
          const Divider(height: 24),
          _KeyValue(label: 'Content type', value: references.first.contentType),
          _KeyValue(
            label: 'Resolver key',
            value: references.first.resolverKey ?? '—',
          ),
          _KeyValue(label: 'SHA-256', value: references.first.checksum),
        ],
      ],
    );
  }
}

class _PipelinePanel extends StatelessWidget {
  const _PipelinePanel({required this.completedSteps, required this.state});

  final int completedSteps;
  final _ResolverState state;

  static const _steps = [
    ('Manifest preflight', 'Point and byte limits checked before I/O'),
    ('Host resolution', 'Host authorizes the resolver key'),
    ('Integrity verification', 'Byte length, SHA-256, and point count match'),
    ('Hydration and table', 'Normal package consumers receive inline data'),
  ];

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Resolution pipeline',
    subtitle: 'Each gate completes before the next begins',
    children: [
      for (var index = 0; index < _steps.length; index++)
        Padding(
          padding: EdgeInsets.only(bottom: index == _steps.length - 1 ? 0 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                index < completedSteps
                    ? Icons.check_circle
                    : state == _ResolverState.error && index == completedSteps
                    ? Icons.cancel
                    : Icons.radio_button_unchecked,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _steps[index].$1,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[index].$2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

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
          const SizedBox(height: 24),
          ...children,
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: 16),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
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

String _differentChecksum(String checksum) {
  final last = checksum[checksum.length - 1];
  return '${checksum.substring(0, checksum.length - 1)}${last == '0' ? '1' : '0'}';
}

List<ChartSeries> _sourceSeries() => [
  LineChartSeries(
    id: 'power',
    name: 'Power',
    unit: 'W',
    color: const Color(0xFF2563EB),
    points: [
      for (var index = 0; index < 120; index++)
        ChartDataPoint(x: index.toDouble(), y: 220 + math.sin(index / 9) * 45),
    ],
  ),
  LineChartSeries(
    id: 'heart-rate',
    name: 'Heart rate',
    unit: 'bpm',
    color: const Color(0xFFDC2626),
    points: [
      for (var index = 0; index < 120; index++)
        ChartDataPoint(x: index.toDouble(), y: 128 + math.sin(index / 12) * 22),
    ],
  ),
];
