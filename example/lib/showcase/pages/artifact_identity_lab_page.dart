import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Interactive checkpoint for canonical hashes and host-side deduplication.
class ArtifactIdentityLabPage extends StatefulWidget {
  const ArtifactIdentityLabPage({super.key});

  @override
  State<ArtifactIdentityLabPage> createState() =>
      _ArtifactIdentityLabPageState();
}

class _ArtifactIdentityLabPageState extends State<ArtifactIdentityLabPage> {
  ChartArtifactDeduplicationScope _scope =
      ChartArtifactDeduplicationScope.document;
  bool _changedPayload = false;

  List<ChartArtifact> get _artifacts {
    final baseDocument = _document();
    return [
      _artifact(
        'snapshot-a',
        baseDocument,
        viewState: ChartViewState(hiddenSeriesIds: const {'heart-rate'}),
      ),
      _artifact(
        'snapshot-a-copy',
        _changedPayload ? _document(lastPower: 267) : _document(),
        viewState: ChartViewState(hiddenSeriesIds: const {'heart-rate'}),
      ),
      _artifact(
        'alternate-view',
        baseDocument,
        viewState: ChartViewState(hiddenSeriesIds: const {'power'}),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifacts = _artifacts;
    final result = ChartArtifactDeduplicator.group(artifacts, scope: _scope);
    final firstDocument = artifacts.first.document;

    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Identity Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Canonical hashes and safe duplicate grouping',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Three artifact envelopes share chart content. Compare document '
            'identity with document-plus-view identity, then change one data '
            'value to invalidate its hashes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SegmentedButton<ChartArtifactDeduplicationScope>(
                segments: const [
                  ButtonSegment(
                    value: ChartArtifactDeduplicationScope.document,
                    label: Text('Document'),
                    icon: Icon(Icons.description_outlined),
                  ),
                  ButtonSegment(
                    value: ChartArtifactDeduplicationScope.view,
                    label: Text('Document + view'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                ],
                selected: {_scope},
                onSelectionChanged: (selection) {
                  setState(() => _scope = selection.single);
                },
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() => _changedPayload = !_changedPayload);
                },
                icon: Icon(
                  _changedPayload ? Icons.undo : Icons.edit_note_outlined,
                ),
                label: Text(
                  _changedPayload ? 'Restore payload' : 'Change payload value',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            inputCount: result.inputCount,
            uniqueCount: result.groups.length,
            duplicateCount: result.duplicateCount,
            scope: _scope,
            changedPayload: _changedPayload,
          ),
          const SizedBox(height: 12),
          Text('Duplicate groups', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          ...result.groups.map(
            (group) => _GroupCard(group: group, scope: _scope),
          ),
          const SizedBox(height: 12),
          Text('Per-payload identities', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final series in firstDocument.series) ...[
                    Text(
                      series.id,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      ChartArtifactCanonicalizer.dataPayloadHash(series.data),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (series != firstDocument.series.last)
                      const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SafetyNote(colorScheme: theme.colorScheme),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.inputCount,
    required this.uniqueCount,
    required this.duplicateCount,
    required this.scope,
    required this.changedPayload,
  });

  final int inputCount;
  final int uniqueCount;
  final int duplicateCount;
  final ChartArtifactDeduplicationScope scope;
  final bool changedPayload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              duplicateCount == 0
                  ? 'No duplicates in this scope'
                  : '$duplicateCount duplicate${duplicateCount == 1 ? '' : 's'} grouped',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric(label: 'Inputs', value: '$inputCount'),
                _Metric(label: 'Unique', value: '$uniqueCount'),
                _Metric(label: 'Duplicates', value: '$duplicateCount'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scope == ChartArtifactDeduplicationScope.document
                  ? 'Artifact envelope metadata and view state are ignored.'
                  : 'Durable view state participates in the identity.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (changedPayload) ...[
              const SizedBox(height: 4),
              Text(
                'A changed Y value now produces a distinct content hash.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label  $value', style: theme.textTheme.labelMedium),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.scope});

  final ChartArtifactDuplicateGroup group;
  final ChartArtifactDeduplicationScope scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ids = [
      group.primary.artifactId,
      ...group.duplicates.map((artifact) => artifact.artifactId),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  group.duplicates.isEmpty
                      ? Icons.fingerprint
                      : Icons.content_copy,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${group.artifactCount} artifact${group.artifactCount == 1 ? '' : 's'}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  scope == ChartArtifactDeduplicationScope.document
                      ? 'DOCUMENT'
                      : 'VIEW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ids.join('  ·  '), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 5),
            SelectableText(
              group.hash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'SHA-256 supports identity, cache keys, and integrity checks. It '
            'does not authenticate who created an artifact; hosts own signing '
            'and trust policy.',
          ),
        ),
      ],
    ),
  );
}

ChartArtifact _artifact(
  String artifactId,
  ChartDocument document, {
  required ChartViewState viewState,
}) => ChartArtifact(
  artifactId: artifactId,
  renderer: const ChartRendererInfo(
    package: 'braven_charts',
    version: 'identity-lab',
  ),
  createdAt: DateTime.utc(2026, 7, 15),
  document: document,
  viewState: viewState,
);

ChartDocument _document({double lastPower = 263}) => ChartDocument(
  documentId: 'identity-lab-document',
  revision: 4,
  series: [
    ChartSeriesDocument(
      type: 'line',
      id: 'power',
      name: 'Power',
      data: InlinePointPayload([_point(1, 241), _point(2, lastPower)]),
    ),
    ChartSeriesDocument(
      type: 'line',
      id: 'heart-rate',
      name: 'Heart rate',
      data: InlinePointPayload([_point(1, 134), _point(2, 141)]),
    ),
  ],
  xAxis: ChartAxisDocument(id: 'x', position: 'bottom', label: 'Sample'),
  axes: [ChartAxisDocument(id: 'y', position: 'left')],
  theme: ChartThemeDocument(),
  interaction: ChartInteractionDocument(),
);

ChartPointDocument _point(double x, double y) => ChartPointDocument(
  x: ChartNumberDocument.fromDouble(x),
  y: ChartNumberDocument.fromDouble(y),
);
