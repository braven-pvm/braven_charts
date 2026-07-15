import 'dart:convert';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// The single product-facing overview for the complete chart-artifact flow.
///
/// The smaller artifact lab pages remain intentionally focused validation
/// fixtures. This page composes their user-visible capabilities into one
/// end-to-end story: capture, inspect, preview, tabulate, persist, restore,
/// and reason about payload compatibility.
class ArtifactShowcasePage extends StatefulWidget {
  const ArtifactShowcasePage({super.key});

  @override
  State<ArtifactShowcasePage> createState() => _ArtifactShowcasePageState();
}

class _ArtifactShowcasePageState extends State<ArtifactShowcasePage> {
  final _sourceController = BravenChartController();
  final _restoredController = BravenChartController();
  final _tableController = ChartTableController();

  ChartArtifact? _artifact;
  ChartTableModel? _table;
  HydratedChartConfiguration? _hydrated;
  String? _canonicalJson;
  String _status = 'Mounting the source chart…';
  String? _error;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  bool _busy = false;
  bool _heartRateVisible = true;
  bool _jsonRoundTripPassed = false;
  int? _pointBytes;
  int? _columnBytes;
  int? _binaryBytes;
  int _restoreCount = 0;

  static final _formatterDescriptor = ChartFormatterDescriptor(
    id: 'showcase.fixed',
    arguments: {'decimals': JsonNumberValue(1)},
    fallbackPattern: '{value}',
  );

  static final _formatterRegistry = ChartFormatterRegistry(
    customFormatters: {
      'showcase.fixed': (value, _) => value.toStringAsFixed(1),
    },
  );

  ChartRuntimeBindings get _runtimeBindings => ChartRuntimeBindings(
    formatters: _formatterRegistry,
    callbacks: ChartCallbackRegistry(
      callbacks: {
        'showcase.seriesSelected': (String seriesId) {
          if (!mounted) return;
          setState(() => _status = 'Restored callback: selected $seriesId');
        },
      },
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _restoredController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Capturing effective data, view state, and preview…';
    });

    final result = await _sourceController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'artifact-showcase',
        createdAt: DateTime.utc(2026, 7, 15, 12),
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'artifact-showcase-document',
          dataStorage: ChartDataStorage.inlineColumns,
          xAxisFormatterDescriptor: _formatterDescriptor.toDocument(),
          yAxisFormatterDescriptors: {'y': _formatterDescriptor.toDocument()},
        ),
        provenance: ChartArtifactProvenance(
          values: JsonObjectValue(const {
            'surface': JsonStringValue('artifact-showcase'),
            'purpose': JsonStringValue('complete feature overview'),
          }),
        ),
      ),
    );

    if (!mounted) return;
    switch (result) {
      case ChartArtifactFailure<ChartArtifact>():
        setState(() {
          _busy = false;
          _error = '${result.error.code}: ${result.error.message}';
          _status = 'Capture failed';
        });
      case ChartArtifactSuccess<ChartArtifact>():
        final artifact = result.value;
        final encoded = ChartArtifactJsonCodec.encode(artifact);
        final json = switch (encoded) {
          ChartArtifactSuccess<String>() => encoded.value,
          ChartArtifactFailure<String>() => null,
        };
        final table = ChartTableModel.fromDocument(
          artifact.document,
          viewState: artifact.viewState,
          options: ChartTableOptions(formatters: _formatterRegistry),
        );
        final hydrated = ChartDocumentHydrator.hydrateArtifact(
          artifact,
          runtimeBindings: _runtimeBindings,
        );
        final hydration = switch (hydrated) {
          ChartArtifactSuccess<HydratedChartConfiguration>() => hydrated.value,
          ChartArtifactFailure<HydratedChartConfiguration>() => null,
        };
        String? hydrationError;
        if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
          hydrationError = '${hydrated.error.code}: ${hydrated.error.message}';
        }

        setState(() {
          _busy = false;
          _artifact = artifact;
          _canonicalJson = json;
          _table = table;
          _hydrated = hydration;
          _jsonRoundTripPassed = false;
          _status = hydration == null
              ? 'Captured the artifact; hydration needs attention.'
              : 'Captured one immutable artifact and prepared an independent runtime.';
          _error = hydrationError;
        });
        _comparePayloads();
    }
  }

  void _roundTripJson() {
    final json = _canonicalJson;
    final artifact = _artifact;
    if (json == null || artifact == null) return;
    final decoded = ChartArtifactJsonCodec.decode(
      json,
      supportedCapabilities: {
        ...artifact.document.requiredCapabilities,
        for (final series in artifact.document.series)
          ...series.requiredCapabilities,
        for (final annotation in artifact.document.annotations)
          ...annotation.requiredCapabilities,
      },
    );
    String? decodeError;
    if (decoded case ChartArtifactFailure<ChartArtifactDecodeResult>()) {
      decodeError = '${decoded.error.code}: ${decoded.error.message}';
    }
    setState(() {
      _jsonRoundTripPassed =
          decoded is ChartArtifactSuccess<ChartArtifactDecodeResult>;
      _status = _jsonRoundTripPassed
          ? 'Schema ${artifact.schemaVersion} round trip passed with canonical JSON.'
          : 'Schema validation reported a compatibility issue.';
      _error = decodeError;
    });
  }

  void _restoreCopy() {
    final json = _canonicalJson;
    if (json == null) return;
    final restored = ChartDocumentHydrator.hydrateJson(
      json,
      runtimeBindings: _runtimeBindings,
    );
    if (restored case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _error = '${restored.error.code}: ${restored.error.message}';
        _status = 'Restore failed';
      });
      return;
    }
    final hydrated =
        (restored as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    setState(() {
      _hydrated = hydrated;
      _restoreCount++;
      _error = null;
      _status =
          'Restored copy $_restoreCount from canonical JSON with fresh runtime bindings.';
    });
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _sourceController.setSeriesVisible('heart-rate', _heartRateVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  void _comparePayloads() {
    final artifact = _artifact;
    if (artifact == null) return;
    final pointDocument = _sourceController.extractDocument(
      const ChartDocumentExtractOptions(
        documentId: 'artifact-showcase-points',
        dataStorage: ChartDataStorage.inlinePoints,
      ),
    );
    final columnDocument = _sourceController.extractDocument(
      const ChartDocumentExtractOptions(
        documentId: 'artifact-showcase-columns',
        dataStorage: ChartDataStorage.inlineColumns,
      ),
    );
    if (pointDocument case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
      final pointArtifact = ChartArtifact(
        artifactId: 'artifact-showcase-points',
        renderer: artifact.renderer,
        createdAt: artifact.createdAt,
        document: pointDocument.value.document,
      );
      final encoded = ChartArtifactJsonCodec.encode(pointArtifact);
      if (encoded case ChartArtifactSuccess<String>()) {
        _pointBytes = utf8.encode(encoded.value).length;
      }
    }
    if (columnDocument case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
      final columnArtifact = ChartArtifact(
        artifactId: 'artifact-showcase-columns',
        renderer: artifact.renderer,
        createdAt: artifact.createdAt,
        document: columnDocument.value.document,
      );
      final encoded = ChartArtifactJsonCodec.encode(columnArtifact);
      if (encoded case ChartArtifactSuccess<String>()) {
        _columnBytes = utf8.encode(encoded.value).length;
      }
      final payload = columnDocument.value.document.series.first.data;
      if (payload is InlineChartDataPayload) {
        final binary = ChartDataBinaryCodec.encode(payload);
        if (binary case ChartArtifactSuccess<ChartDataBlob>()) {
          _binaryBytes = binary.value.bytes.length;
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 760;
    final artifact = _artifact;
    final preview = artifact?.preview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart artifacts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: compact
                ? IconButton.filled(
                    onPressed: _busy ? null : _capture,
                    tooltip: 'Capture artifact',
                    icon: const Icon(Icons.refresh),
                  )
                : FilledButton.icon(
                    onPressed: _busy ? null : _capture,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: const Text('Capture artifact'),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'One chart, every portable surface',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Text(
                      'Capture the effective chart once, then inspect its schema, preview, raw data, payload strategy, and independent restored runtime from the same immutable document.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatusBanner(status: _status, error: _error),
                  const SizedBox(height: 20),
                  _OverviewCards(
                    artifact: artifact,
                    table: _table,
                    preview: preview,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeading(
                    eyebrow: 'LIVE WORKFLOW',
                    title: 'Chart, data, and restored runtime',
                    description:
                        'The table and hydrated chart are projections of the same captured document.',
                  ),
                  const SizedBox(height: 12),
                  _buildWorkflowStage(compact),
                  const SizedBox(height: 28),
                  const _SectionHeading(
                    eyebrow: 'PORTABLE DOCUMENT',
                    title: 'Inspect, validate, and persist',
                    description:
                        'These controls make the transport boundary visible without leaving the page.',
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentGrid(theme),
                  const SizedBox(height: 28),
                  const _SectionHeading(
                    eyebrow: 'CAPABILITY MAP',
                    title: 'What this page proves',
                    description:
                        'Focused lab pages remain available in navigation for test-specific diagnostics.',
                  ),
                  const SizedBox(height: 12),
                  const _CapabilityMap(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStage(bool compact) {
    final table = _table;
    final hydrated = _hydrated;
    final chart = _sourceChart();
    final data = table == null
        ? const _PlaceholderPanel(
            label: 'Capture the chart to build its table.',
          )
        : ChartDataTable(model: table, controller: _tableController);
    final restored = hydrated == null
        ? const _PlaceholderPanel(
            label: 'Capture and hydrate to create a fresh runtime.',
          )
        : hydrated.build(bravenChartController: _restoredController);
    final mode = compact && _displayMode == ChartDisplayMode.split
        ? ChartDisplayMode.chart
        : _displayMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<ChartDisplayMode>(
              segments: [
                const ButtonSegment(
                  value: ChartDisplayMode.chart,
                  icon: Icon(Icons.show_chart),
                  label: Text('Chart'),
                ),
                const ButtonSegment(
                  value: ChartDisplayMode.data,
                  icon: Icon(Icons.table_rows_outlined),
                  label: Text('Data'),
                ),
                if (!compact)
                  const ButtonSegment(
                    value: ChartDisplayMode.split,
                    icon: Icon(Icons.vertical_split_outlined),
                    label: Text('Split'),
                  ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  setState(() => _displayMode = selection.single),
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
            FilledButton.tonalIcon(
              onPressed: hydrated == null ? null : _restoreCopy,
              icon: const Icon(Icons.add_to_photos_outlined),
              label: const Text('Restore independent copy'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: compact ? 520 : 600,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = mode == ChartDisplayMode.split ? 16.0 : 0.0;
              final half = math.max(0.0, (constraints.maxWidth - gap) / 2);
              return Stack(
                children: [
                  if (mode != ChartDisplayMode.data)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: mode == ChartDisplayMode.split
                          ? half
                          : constraints.maxWidth,
                      child: _SurfaceCard(label: 'SOURCE CHART', child: chart),
                    ),
                  if (mode != ChartDisplayMode.chart)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: mode == ChartDisplayMode.split
                          ? half
                          : constraints.maxWidth,
                      child: _SurfaceCard(
                        label: 'NATIVE DATA TABLE',
                        child: data,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: _SurfaceCard(label: 'HYDRATED RUNTIME', child: restored),
        ),
      ],
    );
  }

  Widget _buildDocumentGrid(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 900 ? 1 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: _JsonCard(
              json: _canonicalJson,
              roundTripPassed: _jsonRoundTripPassed,
              onRoundTrip: _roundTripJson,
            ),
          ),
          SizedBox(
            width: width,
            child: _PreviewCard(preview: _artifact?.preview),
          ),
          SizedBox(
            width: width,
            child: _PayloadCard(
              pointBytes: _pointBytes,
              columnBytes: _columnBytes,
              binaryBytes: _binaryBytes,
            ),
          ),
          SizedBox(
            width: width,
            child: _IdentityCard(artifact: _artifact),
          ),
        ],
      );
    },
  );

  Widget _sourceChart() => BravenChartPlus(
    bravenChartController: _sourceController,
    title: 'Training response',
    subtitle: 'Effective data + durable view state',
    annotations: [
      ThresholdAnnotation(
        id: 'power-target',
        axis: AnnotationAxis.y,
        value: 260,
        label: 'Target',
      ),
    ],
    series: [
      LineChartSeries(
        id: 'power',
        name: 'Power',
        unit: 'W',
        color: const Color(0xFF2563EB),
        points: _points(
          (index) =>
              (220 + math.sin(index / 2.4) * 32 + index * 2.5).toDouble(),
        ),
      ),
      LineChartSeries(
        id: 'heart-rate',
        name: 'Heart rate',
        unit: 'bpm',
        color: const Color(0xFFDC2626),
        points: _points(
          (index) =>
              (128 + math.sin(index / 3.5) * 12 + index * 1.2).toDouble(),
        ),
      ),
    ],
  );

  List<ChartDataPoint> _points(double Function(int) y) => [
    for (var index = 0; index < 18; index++)
      ChartDataPoint(
        x: index.toDouble(),
        y: y(index),
        label: index % 6 == 0 ? 'Interval ${index ~/ 6 + 1}' : null,
      ),
  ];
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, this.error});
  final String status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isError = error != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError
                ? colors.onErrorContainer
                : colors.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error ?? status,
              style: TextStyle(
                color: isError
                    ? colors.onErrorContainer
                    : colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({this.artifact, this.table, this.preview});
  final ChartArtifact? artifact;
  final ChartTableModel? table;
  final ChartPreview? preview;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _MetricCard(
        label: 'Schema',
        value: artifact == null ? '—' : 'v${artifact!.schemaVersion}',
        icon: Icons.schema_outlined,
      ),
      _MetricCard(
        label: 'Series',
        value: artifact == null ? '—' : '${artifact!.document.series.length}',
        icon: Icons.stacked_line_chart,
      ),
      _MetricCard(
        label: 'Table rows',
        value: table == null ? '—' : '${table!.rowCount}',
        icon: Icons.table_rows_outlined,
      ),
      _MetricCard(
        label: 'Preview',
        value: preview == null
            ? 'Pending'
            : '${preview!.widthPixels} × ${preview!.heightPixels}',
        icon: Icons.image_outlined,
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({
    required this.json,
    required this.roundTripPassed,
    required this.onRoundTrip,
  });
  final String? json;
  final bool roundTripPassed;
  final VoidCallback onRoundTrip;

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Schema + canonical JSON',
    icon: Icons.data_object,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          json == null
              ? 'Capture the chart to create a deterministic schema-v1 envelope.'
              : '${json!.length} characters · artifactType braven.chartArtifact',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: json == null ? null : onRoundTrip,
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Validate round trip'),
            ),
            const SizedBox(width: 12),
            if (roundTripPassed)
              const Chip(
                avatar: Icon(Icons.check, size: 16),
                label: Text('Validated'),
              ),
          ],
        ),
      ],
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({this.preview});
  final ChartPreview? preview;

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Revision-bound preview',
    icon: Icons.image_outlined,
    child: preview?.bytes == null
        ? const _PlaceholderPanel(label: 'PNG preview appears after capture.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    preview!.bytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${preview!.mimeType} · ${preview!.widthPixels} × ${preview!.heightPixels} · hash matched',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
  );
}

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({this.pointBytes, this.columnBytes, this.binaryBytes});
  final int? pointBytes;
  final int? columnBytes;
  final int? binaryBytes;

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'Payload strategies',
    icon: Icons.view_column_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lossless inline points, inline columns, host-resolved blobs, and compressed binary remain explicit storage choices.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _ValueLine(label: 'Inline points', value: _bytes(pointBytes)),
        _ValueLine(label: 'Inline columns', value: _bytes(columnBytes)),
        _ValueLine(label: 'Binary v1', value: _bytes(binaryBytes)),
      ],
    ),
  );

  String _bytes(int? value) => value == null ? 'Pending' : '$value bytes';
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({this.artifact});
  final ChartArtifact? artifact;

  @override
  Widget build(BuildContext context) {
    final result = artifact == null
        ? null
        : ChartArtifactDeduplicator.group([artifact!, artifact!]);
    return _InfoCard(
      title: 'Identity + compatibility',
      icon: Icons.fingerprint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ValueLine(
            label: 'Document hash',
            value: artifact == null
                ? 'Pending'
                : '${ChartArtifactCanonicalizer.documentHash(artifact!.document).substring(0, 16)}…',
          ),
          _ValueLine(
            label: 'Duplicate groups',
            value: result == null
                ? 'Pending'
                : '${result.groups.length} unique / ${result.duplicateCount} duplicate',
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text('Migrations')),
              Chip(label: Text('Formatter bindings')),
              Chip(label: Text('Validation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 280, child: child),
        ],
      ),
    ),
  );
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _CapabilityMap extends StatelessWidget {
  const _CapabilityMap();

  static const _features = <(IconData, String, String)>[
    (
      Icons.camera_alt_outlined,
      'Effective extraction',
      'Widget, controller, annotation, visibility, and stream state',
    ),
    (
      Icons.schema_outlined,
      'Versioned schema',
      'Deterministic JSON, validation limits, and migrations',
    ),
    (
      Icons.layers_outlined,
      'Interactive hydration',
      'Fresh controllers, view state, and host bindings',
    ),
    (
      Icons.table_rows_outlined,
      'Native data table',
      'Exact-X transposed rows with raw values and series colours',
    ),
    (
      Icons.image_outlined,
      'Preview capture',
      'Optional PNG tied to the document hash',
    ),
    (
      Icons.storage_outlined,
      'Large-data payloads',
      'Columnar, referenced, and compressed binary storage',
    ),
    (
      Icons.fingerprint_outlined,
      'Identity + provenance',
      'Canonical hashes, deduplication, and source metadata',
    ),
    (
      Icons.security_outlined,
      'Safe compatibility',
      'Unknown capabilities warn or fail closed before hydration',
    ),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final feature in _features)
        SizedBox(
          width: 320,
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                feature.$1,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(feature.$2),
              subtitle: Text(feature.$3),
            ),
          ),
        ),
    ],
  );
}
