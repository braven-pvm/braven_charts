import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

// The focused showcase uses a small subset of the legacy diagnostic cards
// below; they remain available as validation fixtures for future lab surfaces.
// ignore_for_file: unused_element, unused_element_parameter

enum _ArtifactFocus { surfaces, transport, preview }

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
  String? _savedJson;
  String _status = 'Preparing an example chart…';
  String? _error;
  _ArtifactFocus _focus = _ArtifactFocus.surfaces;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  bool _includePreview = true;
  bool _busy = false;
  bool _heartRateVisible = true;

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
      _status = 'Saving the chart state and preparing its portable copy…';
    });

    final result = await _sourceController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'artifact-showcase',
        createdAt: DateTime.utc(2026, 7, 15, 12),
        includePreview: _includePreview,
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
          _savedJson = null;
          _table = table;
          _hydrated = hydration;
          _status = hydration == null
              ? 'Chart captured, but the restored copy needs attention.'
              : 'Chart captured. Try the chart, data table, and restored copy below.';
          _error = hydrationError;
        });
    }
  }

  void _restoreCopy() {
    final json = _savedJson;
    if (json == null) {
      setState(() {
        _status = 'Save the portable document first, then restore it here.';
      });
      return;
    }
    final restored = ChartDocumentHydrator.hydrateJson(
      json,
      runtimeBindings: _runtimeBindings,
    );
    if (restored case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _error = '${restored.error.code}: ${restored.error.message}';
        _status = 'The chart could not be restored from this document.';
      });
      return;
    }
    final hydrated =
        (restored as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    setState(() {
      _hydrated = hydrated;
      _error = null;
      _status = 'Restored a fresh chart copy from the portable document.';
    });
  }

  void _saveDocument() {
    final json = _canonicalJson;
    if (json == null) return;
    setState(() {
      _savedJson = json;
      _status =
          'Portable chart saved. This example can now restore it independently.';
      _error = null;
    });
  }

  void _toggleHeartRate() {
    setState(() => _heartRateVisible = !_heartRateVisible);
    _sourceController.setSeriesVisible('heart-rate', _heartRateVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 900;
    return ChartPageLayout(
      title: 'Chart Artifacts',
      subtitle:
          'Explore one chart as a live surface, a data table, a portable document, and an image preview',
      actions: [
        if (compactHeader)
          IconButton(
            tooltip: 'Capture example',
            onPressed: _busy ? null : _capture,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
          )
        else
          FilledButton.icon(
            onPressed: _busy ? null : _capture,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture example'),
          ),
      ],
      optionsChildren: _buildOptionsChildren(),
      bottomPanel: compactHeader
          ? null
          : _StatusBanner(status: _status, error: _error),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptionsChildren() => [
    OptionSection(
      title: 'Showcase focus',
      icon: Icons.hub_outlined,
      children: [
        EnumOption<_ArtifactFocus>(
          label: 'Feature',
          value: _focus,
          values: _ArtifactFocus.values,
          labelBuilder: _focusLabel,
          onChanged: (value) => setState(() => _focus = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Capture and transport',
      icon: Icons.save_outlined,
      children: [
        BoolOption(
          label: 'Create image preview',
          subtitle: 'Attach a revision-bound PNG to the artifact',
          value: _includePreview,
          onChanged: (value) {
            setState(() => _includePreview = value);
            _capture();
          },
        ),
        ActionButton(
          label: 'Capture chart artifact',
          icon: Icons.camera_alt_outlined,
          isPrimary: true,
          onPressed: _capture,
        ),
        if (_canonicalJson != null)
          ActionButton(
            label: 'Save portable document',
            icon: Icons.save_outlined,
            onPressed: _saveDocument,
          ),
        if (_savedJson != null)
          ActionButton(
            label: 'Restore saved copy',
            icon: Icons.restart_alt_outlined,
            onPressed: _restoreCopy,
          ),
      ],
    ),
    OptionSection(
      title: 'How to explore',
      icon: Icons.info_outline,
      children: [InfoBox(message: _focusGuide())],
    ),
  ];

  Widget _buildWorkspace() {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final children = <Widget>[
      Text(
        'Choose a chart-artifact feature',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const SizedBox(height: 168),
      const SizedBox(height: 16),
      _ArtifactGuide(focus: _focus),
      const SizedBox(height: 16),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          SizedBox(
            height: compact ? 520 : 620,
            child: _buildFocusStage(compact),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusRibbon() => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 12.0;
      final width = math.max(220.0, (constraints.maxWidth - 24) / 3);
      return SingleChildScrollView(
        key: const ValueKey('artifact-focus-ribbon'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final focus in _ArtifactFocus.values) ...[
              SizedBox(
                width: width,
                child: _ArtifactFocusCard(
                  key: ValueKey('artifact-focus-${focus.name}'),
                  focus: focus,
                  selected: _focus == focus,
                  onTap: () => setState(() => _focus = focus),
                ),
              ),
              if (focus != _ArtifactFocus.values.last)
                const SizedBox(width: spacing),
            ],
          ],
        ),
      );
    },
  );

  Widget _buildFocusStage(bool compact) => switch (_focus) {
    _ArtifactFocus.surfaces => _buildWorkflowStage(compact),
    _ArtifactFocus.transport => _buildTransportStage(compact),
    _ArtifactFocus.preview => _buildPreviewStage(compact),
  };

  String _focusLabel(_ArtifactFocus focus) => switch (focus) {
    _ArtifactFocus.surfaces => 'Chart, data, or split view',
    _ArtifactFocus.transport => 'Save and restore',
    _ArtifactFocus.preview => 'Create image preview',
  };

  String _focusGuide() => switch (_focus) {
    _ArtifactFocus.surfaces =>
      'Use Chart, Data, or Split to compare the same captured document across product surfaces.',
    _ArtifactFocus.transport =>
      'Save the canonical JSON, then restore a new chart from that saved copy. The restored chart has independent runtime state.',
    _ArtifactFocus.preview =>
      'Capture a PNG preview that is hash-matched to the chart document. Use it for reports, messages, or quick visual confirmation.',
  };

  Widget _buildTransportStage(bool compact) {
    final source = _sourceChart();
    final restored = _hydrated == null
        ? const _PlaceholderPanel(
            label: 'Save the portable document to unlock the restored copy.',
          )
        : _hydrated!.build(bravenChartController: _restoredController);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _canonicalJson == null ? null : _saveDocument,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save portable document'),
            ),
            OutlinedButton.icon(
              onPressed: _savedJson == null ? null : _restoreCopy,
              icon: const Icon(Icons.restart_alt_outlined),
              label: const Text('Restore saved copy'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TransportSteps(saved: _savedJson != null, restored: _hydrated != null),
        const SizedBox(height: 12),
        Expanded(
          child: compact
              ? Column(
                  children: [
                    Expanded(
                      child: _SurfaceCard(label: 'SOURCE CHART', child: source),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _SurfaceCard(
                        label: _savedJson == null
                            ? 'RESTORED COPY · WAITING'
                            : 'RESTORED COPY',
                        child: restored,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SurfaceCard(label: 'SOURCE CHART', child: source),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SurfaceCard(
                        label: _savedJson == null
                            ? 'RESTORED COPY · WAITING'
                            : 'RESTORED COPY',
                        child: restored,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewStage(bool compact) {
    final preview = _artifact?.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _capture,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Create image preview'),
        ),
        const SizedBox(height: 12),
        _PreviewSteps(hasPreview: preview != null),
        const SizedBox(height: 12),
        Expanded(
          child: compact
              ? Column(
                  children: [
                    Expanded(
                      child: _SurfaceCard(
                        label: 'SOURCE CHART',
                        child: _sourceChart(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _SurfaceCard(
                        label: preview == null
                            ? 'IMAGE PREVIEW · WAITING'
                            : 'IMAGE PREVIEW',
                        child: preview == null
                            ? const _PlaceholderPanel(
                                label:
                                    'Capture the artifact to create its PNG preview.',
                              )
                            : _PreviewStageImage(preview: preview),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SurfaceCard(
                        label: 'SOURCE CHART',
                        child: _sourceChart(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SurfaceCard(
                        label: preview == null
                            ? 'IMAGE PREVIEW · WAITING'
                            : 'IMAGE PREVIEW',
                        child: preview == null
                            ? const _PlaceholderPanel(
                                label:
                                    'Capture the artifact to create its PNG preview.',
                              )
                            : _PreviewStageImage(preview: preview),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWorkflowStage(bool compact) {
    final table = _table;
    final chart = _sourceChart();
    final data = table == null
        ? const _PlaceholderPanel(
            label: 'Capture the chart to build its table.',
          )
        : ChartDataTable(model: table, controller: _tableController);
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
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight < 160) {
                return const SizedBox.shrink();
              }
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
      ],
    );
  }

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

class _ArtifactGuide extends StatelessWidget {
  const _ArtifactGuide({required this.focus});

  final _ArtifactFocus focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = switch (focus) {
      _ArtifactFocus.surfaces => (
        Icons.view_quilt_outlined,
        'Chart, data, or split view',
        'The chart and the transposed data table are two views of the same captured document. Split keeps them side by side for comparison.',
      ),
      _ArtifactFocus.transport => (
        Icons.swap_horiz_outlined,
        'A chart that can travel',
        'Save the canonical document, then restore a fresh chart from that saved copy. The restored runtime is independent of the source chart.',
      ),
      _ArtifactFocus.preview => (
        Icons.image_outlined,
        'An image you can send',
        'Create a PNG preview at capture time. The preview is bound to the exact chart document revision it represents.',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(content.$1, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.$2,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(content.$3),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(switch (focus) {
              _ArtifactFocus.surfaces => 'Compare',
              _ArtifactFocus.transport => 'Save → restore',
              _ArtifactFocus.preview => 'Capture PNG',
            }, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _ArtifactFocusCard extends StatelessWidget {
  const _ArtifactFocusCard({
    super.key,
    required this.focus,
    required this.selected,
    required this.onTap,
  });

  final _ArtifactFocus focus;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = switch (focus) {
      _ArtifactFocus.surfaces => (
        Icons.view_quilt_outlined,
        'Chart · data · split',
        'Compare the live chart and its exact-X table.',
      ),
      _ArtifactFocus.transport => (
        Icons.swap_horiz_outlined,
        'Save + restore',
        'Move the chart through a portable document.',
      ),
      _ArtifactFocus.preview => (
        Icons.image_outlined,
        'Image preview',
        'Create a shareable PNG of the captured chart.',
      ),
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      color: selected ? colors.primaryContainer.withValues(alpha: 0.45) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(content.$1, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content.$2,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: colors.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              _FocusVisual(focus: focus),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusVisual extends StatelessWidget {
  const _FocusVisual({required this.focus});

  final _ArtifactFocus focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: switch (focus) {
        _ArtifactFocus.surfaces => const FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VisualPill(label: 'Chart', active: true),
              SizedBox(width: 6),
              _VisualPill(label: 'Data'),
              SizedBox(width: 6),
              _VisualPill(label: 'Split'),
            ],
          ),
        ),
        _ArtifactFocus.transport => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Icon(Icons.restart_alt_outlined, size: 20, color: colors.primary),
          ],
        ),
        _ArtifactFocus.preview => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 20, color: colors.primary),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Icon(Icons.image_outlined, size: 20, color: colors.primary),
          ],
        ),
      },
    );
  }
}

class _VisualPill extends StatelessWidget {
  const _VisualPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: active
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _TransportSteps extends StatelessWidget {
  const _TransportSteps({required this.saved, required this.restored});

  final bool saved;
  final bool restored;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      const _ProgressChip(label: '1 Capture', active: true),
      _ProgressChip(label: '2 Save JSON', active: saved),
      _ProgressChip(label: '3 Restore copy', active: restored),
    ],
  );
}

class _PreviewSteps extends StatelessWidget {
  const _PreviewSteps({required this.hasPreview});

  final bool hasPreview;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      const _ProgressChip(label: '1 Capture chart', active: true),
      _ProgressChip(label: '2 Create PNG', active: hasPreview),
      _ProgressChip(label: '3 Share or embed', active: hasPreview),
    ],
  );
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: active ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _PreviewStageImage extends StatelessWidget {
  const _PreviewStageImage({required this.preview});

  final ChartPreview preview;

  @override
  Widget build(BuildContext context) {
    final bytes = preview.bytes;
    if (bytes == null) {
      return const _PlaceholderPanel(label: 'Preview bytes are not inline.');
    }
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${preview.mimeType} · ${preview.widthPixels} × ${preview.heightPixels} · document hash matched',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _FeatureGuide extends StatelessWidget {
  const _FeatureGuide();

  static const _features = <(IconData, String, String)>[
    (
      Icons.camera_alt_outlined,
      'Capture the effective chart',
      'Keep the data, annotations, styles, visibility, and viewport users actually see.',
    ),
    (
      Icons.ios_share_outlined,
      'Save and share safely',
      'Use deterministic JSON when a chart needs to cross a screen, session, or service boundary.',
    ),
    (
      Icons.table_rows_outlined,
      'Show the data behind it',
      'Project the same document into a compact, transposed table with exact X values.',
    ),
    (
      Icons.image_outlined,
      'Add a preview',
      'Attach a revision-bound image for reports, messages, and quick visual confirmation.',
    ),
    (
      Icons.storage_outlined,
      'Scale for larger data',
      'Choose inline columns, host-resolved data, or compressed binary payloads as needed.',
    ),
    (
      Icons.restart_alt_outlined,
      'Restore with confidence',
      'Validate capabilities and hydrate a fresh runtime without coupling it to the source widget.',
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

class _JourneySteps extends StatelessWidget {
  const _JourneySteps();

  static const _steps = <(IconData, String, String)>[
    (
      Icons.camera_alt_outlined,
      'Capture what is visible',
      'Effective data, styles, annotations, and view state travel together.',
    ),
    (
      Icons.ios_share_outlined,
      'Save or share it',
      'Use canonical JSON, a preview image, or a compact data payload.',
    ),
    (
      Icons.restart_alt_outlined,
      'Restore it later',
      'Hydrate a fresh chart without rebuilding the original widget by hand.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 720
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < _steps.length; index++)
              SizedBox(
                width: width,
                child: _JourneyStep(
                  number: index + 1,
                  icon: _steps[index].$1,
                  title: _steps[index].$2,
                  description: _steps[index].$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text('$number'),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: colors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeExampleCard extends StatelessWidget {
  const _CodeExampleCard();

  static const _code = '''final captured = await controller.extractArtifact(
  const ChartArtifactExtractOptions(
    artifactId: 'workout-2026-07-15',
    includePreview: true,
  ),
);

final json = ChartArtifactJsonCodec.encode(captured.value);
final restored = ChartDocumentHydrator.hydrateJson(
  json.value,
  runtimeBindings: bindings,
);''';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A small API surface for a durable chart',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Capture the effective state once, encode the document for storage or transport, then hydrate it where the user needs it.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.45,
                    color: colors.onSurface,
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
