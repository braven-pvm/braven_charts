import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demonstrates explicit, registered schema migration before hydration.
class ArtifactMigrationLabPage extends StatefulWidget {
  const ArtifactMigrationLabPage({super.key});

  @override
  State<ArtifactMigrationLabPage> createState() =>
      _ArtifactMigrationLabPageState();
}

class _ArtifactMigrationLabPageState extends State<ArtifactMigrationLabPage> {
  _MigrationLabState _state = _MigrationLabState.idle;
  String _status =
      'A demonstration schema-0 fixture is ready for an explicit v0 → v1 migration.';
  String? _errorCode;
  ChartArtifactDecodeResult? _decodeResult;
  HydratedChartConfiguration? _configuration;
  ChartTableModel? _table;

  Future<void> _run({required bool registerMigration}) async {
    setState(() {
      _state = _MigrationLabState.running;
      _status = registerMigration
          ? 'Validating the legacy envelope before running its registered migration.'
          : 'Decoding without a registered migration path.';
      _errorCode = null;
      _decodeResult = null;
      _configuration = null;
      _table = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final encoded = _legacyArtifactJson();
    final migrations = registerMigration
        ? <ChartArtifactMigration>[_ExampleV0ToV1Migration()]
        : const <ChartArtifactMigration>[];
    final decoded = ChartArtifactJsonCodec.decode(
      encoded,
      migrations: migrations,
      supportedCapabilities: const {'series.line'},
    );
    if (decoded case ChartArtifactFailure<ChartArtifactDecodeResult>()) {
      _showFailure(decoded.error);
      return;
    }
    final result =
        (decoded as ChartArtifactSuccess<ChartArtifactDecodeResult>).value;
    final hydrated = ChartDocumentHydrator.hydrateJson(
      encoded,
      migrations: migrations,
    );
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      _showFailure(hydrated.error);
      return;
    }
    setState(() {
      _state = _MigrationLabState.success;
      _decodeResult = result;
      _configuration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
      _table = ChartTableModel.fromDocument(result.artifact.document);
      _status =
          'Migration applied before model construction. The canonical schema-1 '
          'artifact now feeds normal chart and table consumers.';
    });
  }

  void _showFailure(ChartArtifactError error) {
    if (!mounted) return;
    setState(() {
      _state = _MigrationLabState.error;
      _errorCode = error.code;
      _status = '${error.message} Register the adjacent migration and retry.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final running = _state == _MigrationLabState.running;
    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Migration Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade old artifacts explicitly',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Text(
                    'Artifacts cannot select code. The package or host '
                    'registers trusted adjacent migrations, validates their '
                    'output, then constructs current chart models.',
                    style: theme.textTheme.bodyLarge?.copyWith(
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
                        onPressed: running
                            ? null
                            : () => _run(registerMigration: true),
                        icon: const Icon(Icons.upgrade_outlined),
                        label: const Text('Migrate legacy artifact'),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: running
                            ? null
                            : () => _run(registerMigration: false),
                        icon: const Icon(Icons.link_off_outlined),
                        label: const Text('Test missing migration'),
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
                _VersionFlow(result: _decodeResult),
                const SizedBox(height: 24),
                const _RulesCard(),
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
    if (_state == _MigrationLabState.success) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final chart = _ResultCard(
            title: 'Migrated chart',
            subtitle: 'Fresh runtime state from the canonical schema-1 model',
            child: _configuration!.build(),
          );
          final table = _ResultCard(
            title: 'Migrated data table',
            subtitle: 'Values preserved through migration and hydration',
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
      title: _state == _MigrationLabState.error
          ? 'Hydration blocked safely'
          : 'Migrated artifact preview',
      subtitle: _state == _MigrationLabState.error
          ? 'An incomplete migration chain never reaches model construction'
          : 'Run the registered migration to build the chart and table',
      child: Center(
        child: _state == _MigrationLabState.running
            ? const CircularProgressIndicator()
            : Icon(
                _state == _MigrationLabState.error
                    ? Icons.link_off_outlined
                    : Icons.account_tree_outlined,
                size: 56,
              ),
      ),
    );
  }
}

enum _MigrationLabState { idle, running, success, error }

class _ExampleV0ToV1Migration implements ChartArtifactMigration {
  @override
  int get sourceVersion => 0;

  @override
  int get targetVersion => 1;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) {
    final document = Map<String, Object?>.from(
      source['document']! as Map<String, Object?>,
    );
    document['revision'] = document.remove('version');
    return {
      ...source,
      'schemaVersion': 1,
      'artifactId': source['id'],
      'document': document,
    }..remove('id');
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.state,
    required this.status,
    required this.errorCode,
  });

  final _MigrationLabState state;
  final String status;
  final String? errorCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final error = state == _MigrationLabState.error;
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

class _VersionFlow extends StatelessWidget {
  const _VersionFlow({required this.result});

  final ChartArtifactDecodeResult? result;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Source schema', '${result?.sourceSchemaVersion ?? 0}', Icons.history),
      (
        'Applied migration',
        result?.migrationsApplied.join(', ') ?? 'v0->v1 pending',
        Icons.arrow_forward,
      ),
      (
        'Current schema',
        '${result?.migratedSchemaVersion ?? ChartArtifact.currentSchemaVersion}',
        Icons.check_circle_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          for (final item in items)
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$3),
                      const SizedBox(height: 16),
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ];
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                SizedBox(width: double.infinity, child: cards[index].child),
                if (index < cards.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cards[0],
            const SizedBox(width: 16),
            cards[1],
            const SizedBox(width: 16),
            cards[2],
          ],
        );
      },
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Migration contract',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'The schema starts at 1. Schema 0 here is a demonstration fixture, not built-in support.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const _Rule(
            title: 'Adjacent only',
            detail: 'Every step advances exactly one version: vN → vN+1.',
          ),
          const _Rule(
            title: 'Trusted registration',
            detail:
                'Artifacts contain data, never migration class names or code.',
          ),
          const _Rule(
            title: 'Revalidated output',
            detail: 'Limits and semantics run again before model construction.',
          ),
        ],
      ),
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(detail),
            ],
          ),
        ),
      ],
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

String _legacyArtifactJson() {
  final series =
      (ChartSeriesDocumentCodec.encode(
                const LineChartSeries(
                  id: 'power',
                  name: 'Power',
                  unit: 'W',
                  color: Color(0xFF2563EB),
                  points: [
                    ChartDataPoint(x: 0, y: 210),
                    ChartDataPoint(x: 1, y: 225),
                    ChartDataPoint(x: 2, y: 241.44),
                  ],
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  final theme =
      (ChartThemeDocumentCodec.encode(ChartTheme.light)
              as ChartArtifactSuccess<ChartThemeDocument>)
          .value;
  final interaction =
      (ChartInteractionDocumentCodec.encode(const InteractionConfig())
              as ChartArtifactSuccess<ChartInteractionDocument>)
          .value;
  final current = ChartArtifact(
    artifactId: 'migration-lab-artifact',
    renderer: const ChartRendererInfo(
      package: 'braven_charts',
      version: '0.1.0',
    ),
    createdAt: DateTime.utc(2026, 7, 15, 11),
    document: ChartDocument(
      documentId: 'migration-lab-document',
      revision: 7,
      series: [series],
      xAxis: ChartAxisDocument(id: 'sample', position: 'bottom'),
      axes: const [],
      theme: theme,
      interaction: interaction,
    ),
  ).toJson();
  current['schemaVersion'] = 0;
  current['id'] = current.remove('artifactId');
  final document = current['document']! as Map<String, Object?>;
  document['version'] = document.remove('revision');
  return canonicalJsonEncode(current);
}
