import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Proves that portable formatter descriptors require explicit host rebinding.
class ArtifactFormatterBindingLabPage extends StatefulWidget {
  const ArtifactFormatterBindingLabPage({super.key});

  @override
  State<ArtifactFormatterBindingLabPage> createState() =>
      _ArtifactFormatterBindingLabPageState();
}

class _ArtifactFormatterBindingLabPageState
    extends State<ArtifactFormatterBindingLabPage> {
  static const _formatterId = 'com.braven.showcase.watts';

  final _sourceController = BravenChartController();
  final _restoredController = BravenChartController();
  HydratedChartConfiguration? _configuration;
  List<ChartArtifactWarning> _warnings = const [];
  String _sample = '—';
  String _status = 'Choose a restore path to capture the formatter descriptor.';
  bool _bindingActive = false;
  bool _busy = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _restoredController.dispose();
    super.dispose();
  }

  Future<void> _captureAndRestore({required bool registerFormatter}) async {
    setState(() {
      _busy = true;
      _configuration = null;
      _warnings = const [];
      _sample = '—';
      _status = registerFormatter
          ? 'Rebinding the saved descriptor to trusted host code…'
          : 'Restoring without the host formatter to exercise its fallback…';
    });

    final descriptor = ChartFormatterDescriptor(
      id: _formatterId,
      arguments: const {'unit': JsonStringValue('W')},
      fallbackPattern: '{value} W (fallback)',
    );
    final extracted = await _sourceController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'formatter-binding-lab',
        createdAt: DateTime.utc(2026, 7, 15),
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'formatter-binding-document',
          xAxisFormatterDescriptor: descriptor.toDocument(),
        ),
      ),
    );
    if (!mounted) return;
    if (extracted case ChartArtifactFailure<ChartArtifact>()) {
      _showFailure(extracted.error);
      return;
    }
    final encoded = ChartArtifactJsonCodec.encode(
      (extracted as ChartArtifactSuccess<ChartArtifact>).value,
    );
    if (encoded case ChartArtifactFailure<String>()) {
      _showFailure(encoded.error);
      return;
    }

    final bindings = registerFormatter
        ? ChartRuntimeBindings(
            formatters: ChartFormatterRegistry(
              customFormatters: {
                _formatterId: (value, arguments) {
                  final unit = arguments['unit']?.toJson() ?? '';
                  return '${value.toStringAsFixed(0)} $unit · host';
                },
              },
            ),
          )
        : const ChartRuntimeBindings();
    final hydrated = ChartDocumentHydrator.hydrateJson(
      (encoded as ChartArtifactSuccess<String>).value,
      runtimeBindings: bindings,
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      _showFailure(hydrated.error);
      return;
    }
    final success =
        hydrated as ChartArtifactSuccess<HydratedChartConfiguration>;
    final formatter = success.value.xAxis.labelFormatter;
    setState(() {
      _busy = false;
      _bindingActive = registerFormatter;
      _configuration = success.value;
      _warnings = success.warnings;
      _sample = formatter?.call(250) ?? 'No formatter';
      _status = registerFormatter
          ? 'Trusted host formatter rebound by stable ID.'
          : 'Unknown formatter used its portable fallback safely.';
    });
  }

  void _showFailure(ChartArtifactError error) {
    setState(() {
      _busy = false;
      _status = '${error.code}: ${error.message}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Formatter Binding Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Portable descriptor, trusted runtime behavior',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The artifact stores a stable formatter ID, JSON-safe arguments, '
            'and a fallback—not a Dart closure. Compare safe fallback restore '
            'with explicit host registry rebinding.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _ResultCard(
            status: _status,
            sample: _sample,
            warningCount: _warnings.length,
            bindingActive: _bindingActive,
            busy: _busy,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _captureAndRestore(registerFormatter: false),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Restore with fallback'),
              ),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _captureAndRestore(registerFormatter: true),
                icon: const Icon(Icons.link),
                label: const Text('Restore with host binding'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final source = _ChartCard(
                eyebrow: 'SOURCE',
                title: 'Mounted chart',
                subtitle: 'The descriptor is attached during extraction.',
                chart: _sourceChart(),
              );
              final restored = _ChartCard(
                eyebrow: 'RESTORED',
                title: _bindingActive ? 'Host-bound copy' : 'Fallback copy',
                subtitle: _configuration == null
                    ? 'Run either restore path to create this runtime.'
                    : 'Fresh runtime; formatter behavior resolved at import.',
                chart: _configuration == null
                    ? const _Placeholder()
                    : _configuration!.build(
                        bravenChartController: _restoredController,
                      ),
              );
              if (constraints.maxWidth < 1000) {
                return Column(
                  children: [source, const SizedBox(height: 12), restored],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: source),
                  const SizedBox(width: 12),
                  Expanded(child: restored),
                ],
              );
            },
          ),
          if (_warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final warning in _warnings)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.tertiary,
                ),
                title: Text(warning.code),
                subtitle: Text(warning.message),
              ),
          ],
        ],
      ),
    );
  }

  Widget _sourceChart() => BravenChartPlus(
    bravenChartController: _sourceController,
    title: 'Power profile',
    xAxisConfig: const XAxisConfig(label: 'Power', unit: 'W'),
    yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Sample'),
    series: const [
      LineChartSeries(
        id: 'power',
        name: 'Power',
        unit: 'W',
        color: Color(0xFF2563EB),
        points: [
          ChartDataPoint(x: 218, y: 1),
          ChartDataPoint(x: 241, y: 2),
          ChartDataPoint(x: 267, y: 3),
          ChartDataPoint(x: 252, y: 4),
        ],
      ),
    ],
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.status,
    required this.sample,
    required this.warningCount,
    required this.bindingActive,
    required this.busy,
  });

  final String status;
  final String sample;
  final int warningCount;
  final bool bindingActive;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                bindingActive ? Icons.link : Icons.shield_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '250 → $sample  ·  warnings $warningCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.chart,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
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
            Text(title, style: theme.textTheme.titleMedium),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 320, child: chart),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(child: Text('No restored runtime yet')),
  );
}
