import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// End-to-end canonical JSON persistence with fresh restored chart runtimes.
class ArtifactSaveRestoreLabPage extends StatefulWidget {
  const ArtifactSaveRestoreLabPage({super.key});

  @override
  State<ArtifactSaveRestoreLabPage> createState() =>
      _ArtifactSaveRestoreLabPageState();
}

class _ArtifactSaveRestoreLabPageState
    extends State<ArtifactSaveRestoreLabPage> {
  final _sourceController = BravenChartController();
  final List<_RestoredCopy> _restored = [];

  String? _savedJson;
  String? _documentHash;
  String _status = 'Save the mounted chart to create canonical JSON.';
  bool _busy = false;
  bool _heartRateVisible = true;
  int _restoreSerial = 0;

  @override
  void dispose() {
    _sourceController.dispose();
    for (final copy in _restored) {
      copy.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = 'Capturing effective chart and durable view state…';
    });
    final extracted = await _sourceController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'save-restore-lab',
        createdAt: DateTime.utc(2026, 7, 15),
        documentOptions: const ChartDocumentExtractOptions(
          documentId: 'save-restore-document',
        ),
        provenance: ChartArtifactProvenance(
          values: JsonObjectValue(const {
            'example': JsonStringValue('save-restore'),
          }),
        ),
      ),
    );
    if (!mounted) return;
    if (extracted case ChartArtifactFailure<ChartArtifact>()) {
      setState(() {
        _busy = false;
        _status = '${extracted.error.code}: ${extracted.error.message}';
      });
      return;
    }
    final artifact = (extracted as ChartArtifactSuccess<ChartArtifact>).value;
    final encoded = ChartArtifactJsonCodec.encode(artifact);
    if (encoded case ChartArtifactFailure<String>()) {
      setState(() {
        _busy = false;
        _status = '${encoded.error.code}: ${encoded.error.message}';
      });
      return;
    }

    final json = (encoded as ChartArtifactSuccess<String>).value;
    setState(() {
      _busy = false;
      _savedJson = json;
      _documentHash = ChartArtifactCanonicalizer.documentHash(
        artifact.document,
      );
      _status =
          'Saved ${utf8.encode(json).length} bytes of canonical schema-v1 JSON.';
    });
  }

  void _restore() {
    final savedJson = _savedJson;
    if (savedJson == null) return;
    final copyNumber = ++_restoreSerial;
    final hydrated = ChartDocumentHydrator.hydrateJson(
      savedJson,
      runtimeBindings: ChartRuntimeBindings(
        onSeriesSelected: (seriesId) {
          if (!mounted) return;
          setState(() {
            _status = 'Restored copy $copyNumber selected $seriesId.';
          });
        },
      ),
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _status = '${hydrated.error.code}: ${hydrated.error.message}';
      });
      return;
    }
    final copy = _RestoredCopy(
      label: 'Restored copy $copyNumber',
      configuration:
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value,
      controller: BravenChartController(),
    );
    setState(() {
      _restored.add(copy);
      _status =
          '${copy.label} created from persisted JSON with a fresh controller.';
    });
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _sourceController.setSeriesVisible('heart-rate', _heartRateVisible);
  }

  void _removeCopy(_RestoredCopy copy) {
    setState(() => _restored.remove(copy));
    copy.controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Save + Restore Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Persist once, restore independent runtimes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture the mounted chart, encode canonical JSON, then hydrate '
            'multiple copies. Each restored tile owns a fresh controller and '
            'host callback while preserving the saved view state.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _StatusCard(
            status: _status,
            savedJson: _savedJson,
            documentHash: _documentHash,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save canonical JSON'),
              ),
              FilledButton.tonalIcon(
                onPressed: _savedJson == null || _restored.length >= 4
                    ? null
                    : _restore,
                icon: const Icon(Icons.add_to_photos_outlined),
                label: const Text('Restore another copy'),
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
          ),
          const SizedBox(height: 16),
          _ChartTile(
            eyebrow: 'SOURCE',
            title: 'Mounted chart',
            subtitle: 'Change visibility, then save a new snapshot.',
            chart: _sourceChart(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Restored comparison gallery',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Chip(label: Text('${_restored.length} copies')),
            ],
          ),
          const SizedBox(height: 8),
          if (_restored.isEmpty)
            const _EmptyGallery()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 1000
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final copy in _restored)
                      SizedBox(
                        width: width,
                        child: _ChartTile(
                          eyebrow: 'RESTORED',
                          title: copy.label,
                          subtitle:
                              'Fresh runtime restored from the same saved JSON.',
                          chart: copy.configuration.build(
                            bravenChartController: copy.controller,
                          ),
                          actions: [
                            TextButton.icon(
                              onPressed: () =>
                                  copy.controller.selectSeries('power'),
                              icon: const Icon(Icons.touch_app_outlined),
                              label: const Text('Select power'),
                            ),
                            IconButton(
                              onPressed: () => _removeCopy(copy),
                              tooltip: 'Remove ${copy.label}',
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sourceChart() => BravenChartPlus(
    bravenChartController: _sourceController,
    title: 'Training response',
    subtitle: 'Save/restore source',
    series: const [
      LineChartSeries(
        id: 'power',
        name: 'Power',
        unit: 'W',
        color: Color(0xFF2563EB),
        points: [
          ChartDataPoint(x: 1, y: 210),
          ChartDataPoint(x: 2, y: 238),
          ChartDataPoint(x: 3, y: 264),
          ChartDataPoint(x: 4, y: 252),
          ChartDataPoint(x: 5, y: 281),
        ],
      ),
      LineChartSeries(
        id: 'heart-rate',
        name: 'Heart rate',
        unit: 'bpm',
        color: Color(0xFFDC2626),
        points: [
          ChartDataPoint(x: 1, y: 126),
          ChartDataPoint(x: 2, y: 135),
          ChartDataPoint(x: 3, y: 147),
          ChartDataPoint(x: 4, y: 151),
          ChartDataPoint(x: 5, y: 159),
        ],
      ),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.savedJson,
    required this.documentHash,
  });

  final String status;
  final String? savedJson;
  final String? documentHash;

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
              savedJson == null ? 'No saved artifact' : 'Canonical JSON ready',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (documentHash != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                documentHash!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartTile extends StatelessWidget {
  const _ChartTile({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.chart,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget chart;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(height: 300, child: chart),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: const Text('Save the source, then restore one or more copies.'),
  );
}

class _RestoredCopy {
  const _RestoredCopy({
    required this.label,
    required this.configuration,
    required this.controller,
  });

  final String label;
  final HydratedChartConfiguration configuration;
  final BravenChartController controller;
}
