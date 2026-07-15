import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Side-by-side live proof of capture, hydration, and runtime independence.
class ArtifactHydrationLabPage extends StatefulWidget {
  const ArtifactHydrationLabPage({super.key});

  @override
  State<ArtifactHydrationLabPage> createState() =>
      _ArtifactHydrationLabPageState();
}

class _ArtifactHydrationLabPageState extends State<ArtifactHydrationLabPage> {
  final _sourceController = BravenChartController();
  final _hydratedController = BravenChartController();

  HydratedChartConfiguration? _hydrated;
  ChartArtifactError? _error;
  int _warningCount = 0;
  int _capturedRevision = 0;
  bool _heartRateVisible = true;
  String _runtimeMessage = 'Hydrate a copy to test its independent runtime.';

  @override
  void dispose() {
    _sourceController.dispose();
    _hydratedController.dispose();
    super.dispose();
  }

  void _captureAndHydrate() {
    final extracted = _sourceController.extractDocument(
      const ChartDocumentExtractOptions(documentId: 'hydration-lab'),
    );
    if (extracted case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      setState(() => _error = extracted.error);
      return;
    }
    final snapshot =
        (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
    final hydrated = ChartDocumentHydrator.hydrateDocument(
      snapshot.document,
      viewState: snapshot.viewState,
      runtimeBindings: ChartRuntimeBindings(
        onSeriesSelected: (seriesId) {
          setState(() {
            _runtimeMessage = 'Hydrated callback: selected $seriesId';
          });
        },
      ),
    );
    switch (hydrated) {
      case ChartArtifactSuccess<HydratedChartConfiguration>():
        setState(() {
          _hydrated = hydrated.value;
          _capturedRevision = snapshot.document.revision;
          _warningCount = hydrated.warnings.length;
          _error = null;
          _runtimeMessage =
              'Hydrated copy ready. Its controllers and interactions are fresh.';
        });
      case ChartArtifactFailure<HydratedChartConfiguration>():
        setState(() => _error = hydrated.error);
    }
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _sourceController.setSeriesVisible('heart-rate', _heartRateVisible);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Hydration Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _captureAndHydrate,
                    tooltip: 'Capture and hydrate',
                    icon: const Icon(Icons.content_copy_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _captureAndHydrate,
                    icon: const Icon(Icons.content_copy_outlined),
                    label: const Text('Capture + hydrate'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One document, independent chart runtimes',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Change the source view, capture it, and hydrate a normal '
                  'interactive chart. Selecting the hydrated chart proves host '
                  'callbacks were rebound without sharing source controllers.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _StatusPanel(
                  error: _error,
                  message: _runtimeMessage,
                  revision: _capturedRevision,
                  warningCount: _warningCount,
                  hydrated: _hydrated != null,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final source = _chartCard(
                      context,
                      eyebrow: 'SOURCE',
                      title: 'Mounted chart',
                      description:
                          'Visibility changes become durable view state.',
                      chart: _sourceChart(),
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _toggleHeartRate,
                          icon: Icon(
                            _heartRateVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          label: Text(
                            _heartRateVisible
                                ? 'Hide heart rate'
                                : 'Show heart rate',
                          ),
                        ),
                      ],
                    );
                    final hydrated = _chartCard(
                      context,
                      eyebrow: 'HYDRATED',
                      title: 'Independent copy',
                      description: _hydrated == null
                          ? 'Capture the source to create this runtime.'
                          : 'Data, styling, annotations, and view state restored.',
                      chart: _hydrated == null
                          ? const _HydrationPlaceholder()
                          : _hydrated!.build(
                              bravenChartController: _hydratedController,
                            ),
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _hydrated == null
                              ? null
                              : () => _hydratedController.selectSeries('power'),
                          icon: const Icon(Icons.touch_app_outlined),
                          label: const Text('Select hydrated power'),
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 1050) {
                      return Column(
                        children: [
                          source,
                          const SizedBox(height: 20),
                          hydrated,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: source),
                        const SizedBox(width: 20),
                        Expanded(child: hydrated),
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

  Widget _sourceChart() => BravenChartPlus(
    bravenChartController: _sourceController,
    title: 'Training response',
    subtitle: 'Portable source chart',
    annotations: [
      ThresholdAnnotation(
        id: 'power-target',
        axis: AnnotationAxis.y,
        value: 260,
        label: 'Target',
      ),
    ],
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

  Widget _chartCard(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String description,
    required Widget chart,
    required List<Widget> actions,
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
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 380, child: chart),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: actions),
        ],
      ),
    ),
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.error,
    required this.message,
    required this.revision,
    required this.warningCount,
    required this.hydrated,
  });

  final ChartArtifactError? error;
  final String message;
  final int revision;
  final int warningCount;
  final bool hydrated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = error == null
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            error == null ? Icons.check_circle_outline : Icons.error_outline,
          ),
          Text(error == null ? message : '${error!.code}: ${error!.message}'),
          if (hydrated) Chip(label: Text('Revision $revision')),
          if (hydrated) Chip(label: Text('Warnings $warningCount')),
        ],
      ),
    );
  }
}

class _HydrationPlaceholder extends StatelessWidget {
  const _HydrationPlaceholder();

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
          Icon(Icons.layers_outlined, size: 42),
          SizedBox(height: 12),
          Text('No hydrated runtime yet'),
        ],
      ),
    ),
  );
}
