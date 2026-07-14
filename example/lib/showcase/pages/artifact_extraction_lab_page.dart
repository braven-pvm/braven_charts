import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Live surface for exercising controller-driven effective document capture.
class ArtifactExtractionLabPage extends StatefulWidget {
  const ArtifactExtractionLabPage({super.key});

  @override
  State<ArtifactExtractionLabPage> createState() =>
      _ArtifactExtractionLabPageState();
}

class _ArtifactExtractionLabPageState extends State<ArtifactExtractionLabPage> {
  final _bravenController = BravenChartController();
  final _dataController = ChartController();
  final _annotationController = AnnotationController(
    initialAnnotations: [
      ThresholdAnnotation(
        id: 'target-power',
        axis: AnnotationAxis.y,
        value: 260,
        label: 'Target 260 W',
      ),
    ],
  );
  final _liveController = LiveStreamController(seriesId: 'heart-rate');

  ChartDocumentSnapshot? _snapshot;
  ChartArtifactError? _error;
  String _json = 'Capture the chart to inspect its immutable document.';
  int _nextX = 7;
  bool _heartRateVisible = true;

  @override
  void dispose() {
    _bravenController.dispose();
    _dataController.dispose();
    _annotationController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  void _extract() {
    final result = _bravenController.extractDocument(
      const ChartDocumentExtractOptions(documentId: 'showcase-live-capture'),
    );
    switch (result) {
      case ChartArtifactSuccess<ChartDocumentSnapshot>():
        final snapshot = result.value;
        setState(() {
          _snapshot = snapshot;
          _error = null;
          _json = const JsonEncoder.withIndent('  ').convert({
            'document': snapshot.document.toJson(),
            if (snapshot.viewState != null)
              'viewState': snapshot.viewState!.toJson(),
          });
        });
      case ChartArtifactFailure<ChartDocumentSnapshot>():
        setState(() {
          _error = result.error;
          _json = '${result.error.code}: ${result.error.message}';
        });
    }
  }

  void _addControllerPoint() {
    final x = _nextX++;
    _dataController.addPoint(
      'power',
      ChartDataPoint(x: x.toDouble(), y: 220 + (x % 4) * 18),
    );
  }

  void _addLivePoint() {
    final x = _nextX++;
    _liveController.addPoint(
      ChartDataPoint(x: x.toDouble(), y: 142 + (x % 5) * 4),
    );
    setState(() {});
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _bravenController.setSeriesVisible('heart-rate', _heartRateVisible);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artifact Extraction Lab'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _extract,
                    tooltip: 'Capture document',
                    icon: const Icon(Icons.camera_outlined),
                  )
                : FilledButton.icon(
                    onPressed: _extract,
                    icon: const Icon(Icons.camera_outlined),
                    label: const Text('Capture document'),
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
                  'Effective state, captured live',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add data through either controller, change visibility, then '
                  'capture. The document is assembled from resolved source state '
                  'and current view state—not render elements.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chart = _buildChartCard(context);
                    final inspector = _buildInspectorCard(context);
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

  Widget _buildChartCard(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live chart', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Widget series + ChartController + LiveStreamController',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: BravenChartPlus(
              bravenChartController: _bravenController,
              controller: _dataController,
              annotationController: _annotationController,
              liveStreamController: _liveController,
              title: 'Training response',
              subtitle: 'Power and heart rate',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _addControllerPoint,
                icon: const Icon(Icons.add_chart),
                label: const Text('Add controller point'),
              ),
              OutlinedButton.icon(
                onPressed: _addLivePoint,
                icon: const Icon(Icons.bolt),
                label: const Text('Add live point'),
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
        ],
      ),
    ),
  );

  Widget _buildInspectorCard(BuildContext context) {
    final theme = Theme.of(context);
    final document = _snapshot?.document;
    final statusColor = _error == null
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _error == null ? Icons.inventory_2_outlined : Icons.error,
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error == null ? 'Captured document' : 'Capture failed',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Revision',
                  value: '${document?.revision ?? 0}',
                ),
                _MetricChip(
                  label: 'Series',
                  value: '${document?.series.length ?? 0}',
                ),
                _MetricChip(
                  label: 'Points',
                  value: '${document?.pointCount ?? 0}',
                ),
                _MetricChip(
                  label: 'Annotations',
                  value: '${document?.annotations.length ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 500,
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _json,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label  $value'));
}
