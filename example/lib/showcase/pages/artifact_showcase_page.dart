import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/portable_chart_showcase_generator.dart';
import '../widgets/standard_options.dart';

enum _ArtifactInspectorMode { data, json }

class ArtifactShowcasePage extends StatefulWidget {
  const ArtifactShowcasePage({super.key});

  @override
  State<ArtifactShowcasePage> createState() => _ArtifactShowcasePageState();
}

class _ArtifactShowcasePageState extends State<ArtifactShowcasePage> {
  static final _twoDecimalFormatter = ChartFormatterDescriptor(
    id: 'braven.number.fixed',
    arguments: {'decimals': JsonNumberValue(2)},
  ).toDocument();

  final _sourceController = BravenChartController();
  final _restoredController = BravenChartController();
  final _tableController = ChartTableController();
  final _inspectorKey = GlobalKey();

  late PortableShowcaseChartStory _generated;
  ChartTableModel? _liveTable;
  final List<_CapturedArtifactEntry> _captures = [];
  String? _selectedCaptureId;
  String? _restoredCaptureId;
  HydratedChartConfiguration? _restoredConfiguration;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  _ArtifactInspectorMode _inspectorMode = _ArtifactInspectorMode.data;
  int _generation = 0;
  int _seed = 7162026;
  int _captureSequence = 0;
  bool _busy = false;
  String _status =
      'Generate a chart, capture it, then inspect or restore the saved copy.';
  String? _error;

  @override
  void initState() {
    super.initState();
    _generated = _nextGeneratedChart();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiveTable());
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _restoredController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  PortableShowcaseChartStory _nextGeneratedChart() {
    _generation += 1;
    final previousKind = _generation == 1 ? null : _generated.kind;
    PortableShowcaseChartStory story;
    do {
      story = PortableChartShowcaseGenerator.generate(_seed++);
    } while (story.kind == previousKind);
    return story;
  }

  void _generateRandomChart() {
    if (_busy) return;
    setState(() {
      _generated = _nextGeneratedChart();
      _liveTable = null;
      _restoredCaptureId = null;
      _restoredConfiguration = null;
      _displayMode = ChartDisplayMode.split;
      _error = null;
      _status =
          'Generated ${_generated.kindLabel.toLowerCase()} seed ${_generated.seed} with fresh data and presentation. Capture it to keep a portable copy.';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiveTable());
  }

  void _refreshLiveTable([int attachmentAttempt = 0]) {
    if (!mounted || _restoredConfiguration != null) return;
    final result = _sourceController.extractDocument(
      _tableDocumentOptions('live-generation-${_generated.seed}'),
    );
    if (result case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
      final table = ChartTableModel.fromDocument(
        result.value.document,
        viewState: result.value.viewState,
      );
      setState(() => _liveTable = table);
      return;
    }
    if (result case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      if (result.error.code == ChartArtifactDiagnosticCodes.chartNotAttached &&
          attachmentAttempt < 2) {
        WidgetsBinding.instance.scheduleFrame();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _refreshLiveTable(attachmentAttempt + 1),
        );
      }
    }
  }

  ChartDocumentExtractOptions _tableDocumentOptions(String documentId) =>
      ChartDocumentExtractOptions(
        documentId: documentId,
        dataStorage: ChartDataStorage.inlineColumns,
        yAxisFormatterDescriptors: {'y': _twoDecimalFormatter},
      );

  Future<ChartArtifactResult<ChartArtifact>> _extractAttachedArtifact(
    BravenChartController controller,
    ChartArtifactExtractOptions options,
  ) async {
    ChartArtifactResult<ChartArtifact>? lastResult;
    for (
      var attachmentAttempt = 0;
      attachmentAttempt < 3;
      attachmentAttempt++
    ) {
      final result = await controller.extractArtifact(options);
      lastResult = result;
      if (result is ChartArtifactSuccess<ChartArtifact>) return result;
      if (result case ChartArtifactFailure<ChartArtifact>()) {
        if (result.error.code !=
                ChartArtifactDiagnosticCodes.chartNotAttached ||
            attachmentAttempt == 2) {
          return result;
        }
      }
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return result;
    }
    return lastResult!;
  }

  Future<void> _captureCurrentChart() async {
    if (_busy) return;
    if (_displayMode == ChartDisplayMode.data) {
      setState(() => _displayMode = ChartDisplayMode.chart);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Capturing the chart document and creating its PNG preview…';
    });

    final sequence = ++_captureSequence;
    final sourceEntry = _restoredEntry;
    final controller = _restoredConfiguration == null
        ? _sourceController
        : _restoredController;
    final result = await _extractAttachedArtifact(
      controller,
      ChartArtifactExtractOptions(
        artifactId: 'showcase-capture-$sequence',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: _tableDocumentOptions(
          'showcase-capture-$sequence-document',
        ),
        provenance: ChartArtifactProvenance(
          values: JsonObjectValue({
            'surface': const JsonStringValue('artifact-showcase'),
            'source': JsonStringValue(
              sourceEntry == null ? 'random-generator' : sourceEntry.artifactId,
            ),
            'seed': JsonNumberValue(_generated.seed),
            'family': JsonStringValue(_generated.kind.name),
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
          _status = 'Capture failed. Keep the chart visible and try again.';
        });
      case ChartArtifactSuccess<ChartArtifact>():
        final artifact = result.value;
        final encoded = ChartArtifactJsonCodec.encode(artifact);
        if (encoded case ChartArtifactFailure<String>()) {
          setState(() {
            _busy = false;
            _error = '${encoded.error.code}: ${encoded.error.message}';
            _status = 'The chart was captured but could not be encoded.';
          });
          return;
        }
        final json = (encoded as ChartArtifactSuccess<String>).value;
        final hydrated = ChartDocumentHydrator.hydrateJson(
          json,
          runtimeBindings: _runtimeBindings,
        );
        if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
          setState(() {
            _busy = false;
            _error = '${hydrated.error.code}: ${hydrated.error.message}';
            _status = 'The chart was captured but could not be restored.';
          });
          return;
        }
        final table = ChartTableModel.fromDocument(
          artifact.document,
          viewState: artifact.viewState,
        );
        final entry = _CapturedArtifactEntry(
          sequence: sequence,
          artifact: artifact,
          json: json,
          table: table,
          hydrated:
              (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>)
                  .value,
        );
        setState(() {
          _busy = false;
          _captures.insert(0, entry);
          _selectedCaptureId = entry.artifactId;
          _inspectorMode = _ArtifactInspectorMode.data;
          _status =
              'Captured “${entry.title}”. It is now stored in the artifact library with its data and preview.';
        });
    }
  }

  ChartRuntimeBindings get _runtimeBindings => ChartRuntimeBindings(
    callbacks: ChartCallbackRegistry(
      callbacks: {
        'showcase.seriesSelected': (String seriesId) {
          if (!mounted) return;
          setState(() => _status = 'Restored callback selected $seriesId.');
        },
      },
    ),
  );

  void _selectCapture(
    _CapturedArtifactEntry entry, {
    _ArtifactInspectorMode? inspectorMode,
  }) {
    setState(() {
      _selectedCaptureId = entry.artifactId;
      if (inspectorMode != null) _inspectorMode = inspectorMode;
      _status =
          'Selected capture ${entry.sequence}. Inspect its data or restore it into the main chart.';
      _error = null;
    });
  }

  void _restoreSelectedCapture() {
    final entry = _selectedEntry;
    if (entry == null) {
      setState(() => _status = 'Select a captured chart before restoring.');
      return;
    }
    setState(() {
      _restoredCaptureId = entry.artifactId;
      _restoredConfiguration = entry.hydrated;
      _displayMode = ChartDisplayMode.split;
      _status =
          'Restored capture ${entry.sequence}. The main surface now comes from the saved JSON document.';
      _error = null;
    });
  }

  void _showSelectedData() {
    if (_selectedEntry == null) {
      setState(() => _status = 'Select a captured chart before inspecting it.');
      return;
    }
    setState(() {
      _inspectorMode = _ArtifactInspectorMode.data;
      _status = 'Showing the exact data stored in the selected chart artifact.';
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inspectorContext = _inspectorKey.currentContext;
      if (inspectorContext == null) return;
      Scrollable.ensureVisible(
        inspectorContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _returnToGenerator() {
    setState(() {
      _restoredCaptureId = null;
      _restoredConfiguration = null;
      _displayMode = ChartDisplayMode.split;
      _status = 'Returned to the live random generator.';
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiveTable());
  }

  _CapturedArtifactEntry? get _selectedEntry {
    for (final entry in _captures) {
      if (entry.artifactId == _selectedCaptureId) return entry;
    }
    return null;
  }

  _CapturedArtifactEntry? get _restoredEntry {
    for (final entry in _captures) {
      if (entry.artifactId == _restoredCaptureId) return entry;
    }
    return null;
  }

  ChartTableModel? get _activeTable => _restoredEntry?.table ?? _liveTable;

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 900;
    return ChartPageLayout(
      title: 'Chart Artifacts',
      subtitle:
          'Generate charts, capture portable copies, restore them, and inspect the data they carry',
      actions: compactHeader
          ? [
              IconButton(
                tooltip: 'Generate random chart',
                onPressed: _generateRandomChart,
                icon: const Icon(Icons.casino_outlined),
              ),
              IconButton.filled(
                tooltip: 'Capture current chart',
                onPressed: _captureCurrentChart,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
              ),
            ]
          : [
              OutlinedButton.icon(
                onPressed: _generateRandomChart,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Generate random chart'),
              ),
              FilledButton.icon(
                onPressed: _captureCurrentChart,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_busy ? 'Capturing…' : 'Capture current chart'),
              ),
            ],
      chart: _buildWorkbench(),
    );
  }

  Widget _buildWorkbench() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkflowStrip(
              hasCaptures: _captures.isNotEmpty,
              hasSelection: _selectedEntry != null,
              hasRestored: _restoredEntry != null,
            ),
            const SizedBox(height: 12),
            const _ArtifactPromise(),
            const SizedBox(height: 16),
            _StatusBanner(status: _status, error: _error),
            const SizedBox(height: 16),
            if (wide)
              SizedBox(
                height: 560,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildActiveChartPanel()),
                    const SizedBox(width: 16),
                    SizedBox(width: 360, child: _buildArtifactLibrary()),
                  ],
                ),
              )
            else ...[
              SizedBox(height: 540, child: _buildActiveChartPanel()),
              const SizedBox(height: 16),
              SizedBox(height: 440, child: _buildArtifactLibrary()),
            ],
            if (_selectedEntry != null) ...[
              const SizedBox(height: 24),
              SizedBox(height: 440, child: _buildArtifactInspector()),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );

  Widget _buildActiveChartPanel() {
    final restored = _restoredEntry;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SurfaceBadge(
                        restored: restored != null,
                        label: restored == null
                            ? 'LIVE GENERATOR'
                            : 'RESTORED FROM CAPTURE ${restored.sequence}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        restored?.title ?? _generated.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restored?.summary ?? _generated.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (restored == null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _TinyLabel(
                              icon: Icons.auto_awesome_outlined,
                              label: 'Seed ${_generated.seed}',
                            ),
                            _TinyLabel(
                              icon: Icons.category_outlined,
                              label: _generated.kindLabel,
                            ),
                            _TinyLabel(
                              icon: Icons.data_array_outlined,
                              label: '${_generated.pointCount} source values',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generated.explanation,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (restored != null)
                  TextButton.icon(
                    onPressed: _returnToGenerator,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Return to generator'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ChartDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: ChartDisplayMode.chart,
                    icon: Icon(Icons.show_chart),
                    label: Text('Chart'),
                  ),
                  ButtonSegment(
                    value: ChartDisplayMode.data,
                    icon: Icon(Icons.table_rows_outlined),
                    label: Text('Data'),
                  ),
                  ButtonSegment(
                    value: ChartDisplayMode.split,
                    icon: Icon(Icons.vertical_split_outlined),
                    label: Text('Split'),
                  ),
                ],
                selected: {_displayMode},
                onSelectionChanged: (selection) {
                  setState(() => _displayMode = selection.single);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildActiveSurface()),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSurface() {
    final chart = _restoredConfiguration == null
        ? BravenChartPlus(
            key: const ValueKey('live-generated-chart'),
            bravenChartController: _sourceController,
            title: _generated.title,
            subtitle: _generated.subtitle,
            annotations: _generated.annotations,
            series: _generated.series,
            theme: _generated.theme,
            showLegend: _generated.showLegend,
            xAxisConfig: _generated.xAxisConfig,
            yAxis: _generated.yAxis,
          )
        : _restoredConfiguration!.build(
            key: const ValueKey('restored-chart'),
            bravenChartController: _restoredController,
          );
    final table = _activeTable;
    final data = table == null
        ? const _EmptyPanel(
            icon: Icons.hourglass_top_outlined,
            title: 'Preparing data table',
            message: 'The exact-X table will appear after the chart is ready.',
          )
        : ChartDataTable(
            key: ValueKey('active-table-${table.documentId}'),
            model: table,
            controller: _tableController,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final canSplit = constraints.maxWidth >= 720;
        final effectiveMode =
            !canSplit && _displayMode == ChartDisplayMode.split
            ? ChartDisplayMode.chart
            : _displayMode;
        if (effectiveMode == ChartDisplayMode.chart) {
          return _SurfaceFrame(label: 'CHART', child: chart);
        }
        if (effectiveMode == ChartDisplayMode.data) {
          return _SurfaceFrame(label: 'DATA TABLE', child: data);
        }
        return Row(
          children: [
            Expanded(
              child: _SurfaceFrame(label: 'CHART', child: chart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SurfaceFrame(label: 'DATA TABLE', child: data),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtifactLibrary() => _ArtifactLibrary(
    captures: _captures,
    selectedId: _selectedCaptureId,
    restoredId: _restoredCaptureId,
    busy: _busy,
    onSelect: _selectCapture,
    onRestore: _restoreSelectedCapture,
    onInspect: _showSelectedData,
    onCapture: _captureCurrentChart,
  );

  Widget _buildArtifactInspector() {
    final entry = _selectedEntry!;
    return Card(
      key: _inspectorKey,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.manage_search_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspect capture ${entry.sequence}: ${entry.title}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${entry.summary} · ${entry.jsonBytesLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<_ArtifactInspectorMode>(
                  segments: const [
                    ButtonSegment(
                      value: _ArtifactInspectorMode.data,
                      icon: Icon(Icons.table_rows_outlined),
                      label: Text('Captured data'),
                    ),
                    ButtonSegment(
                      value: _ArtifactInspectorMode.json,
                      icon: Icon(Icons.data_object),
                      label: Text('Raw JSON'),
                    ),
                  ],
                  selected: {_inspectorMode},
                  onSelectionChanged: (selection) {
                    setState(() => _inspectorMode = selection.single);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _inspectorMode == _ArtifactInspectorMode.data
                  ? ChartDataTable(
                      key: ValueKey('captured-data-${entry.artifactId}'),
                      model: entry.table,
                    )
                  : _RawJsonViewer(json: entry.prettyJson),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedArtifactEntry {
  _CapturedArtifactEntry({
    required this.sequence,
    required this.artifact,
    required this.json,
    required this.table,
    required this.hydrated,
  }) : thumbnailProvider = _thumbnailProviderFor(artifact),
       prettyJson = const JsonEncoder.withIndent(
         '  ',
       ).convert(jsonDecode(json));

  final int sequence;
  final ChartArtifact artifact;
  final String json;
  final String prettyJson;
  final ChartTableModel table;
  final HydratedChartConfiguration hydrated;
  final MemoryImage? thumbnailProvider;

  String get artifactId => artifact.artifactId;
  String get title => artifact.document.title ?? 'Untitled chart';
  String get typeLabel {
    final types = artifact.document.series.map((series) => series.type).toSet();
    return types.length == 1 ? types.single.toUpperCase() : 'MIXED';
  }

  String get summary =>
      '$typeLabel · ${artifact.document.series.length} series · ${artifact.document.pointCount} points';
  String get jsonBytesLabel => '${utf8.encode(json).length} JSON bytes';
  String get capturedTime {
    final local = artifact.createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

MemoryImage? _thumbnailProviderFor(ChartArtifact artifact) {
  // ChartPreview.bytes returns a defensive copy. Resolve it once per capture
  // so unrelated page rebuilds retain the same image-cache key and frame.
  final bytes = artifact.preview?.bytes;
  return bytes == null ? null : MemoryImage(bytes);
}

class _WorkflowStrip extends StatelessWidget {
  const _WorkflowStrip({
    required this.hasCaptures,
    required this.hasSelection,
    required this.hasRestored,
  });

  final bool hasCaptures;
  final bool hasSelection;
  final bool hasRestored;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final steps = [
        const _WorkflowStep(
          number: 1,
          title: 'Explore',
          detail: 'Generate a real chart and switch Chart, Data, or Split',
          complete: true,
        ),
        _WorkflowStep(
          number: 2,
          title: 'Capture',
          detail: 'Extract resolved data, state, styling, and a PNG preview',
          complete: hasCaptures,
        ),
        _WorkflowStep(
          number: 3,
          title: 'Inspect',
          detail: 'Select a saved copy and read its native table or JSON',
          complete: hasSelection,
        ),
        _WorkflowStep(
          number: 4,
          title: 'Restore',
          detail: 'Hydrate the saved JSON into a fresh interactive chart',
          complete: hasRestored,
        ),
      ];
      if (constraints.maxWidth < 720) {
        return Column(
          children: [
            for (final step in steps) ...[
              step,
              if (step != steps.last) const SizedBox(height: 8),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (final step in steps) ...[
            Expanded(child: step),
            if (step != steps.last) const SizedBox(width: 12),
          ],
        ],
      );
    },
  );
}

class _ArtifactPromise extends StatelessWidget {
  const _ArtifactPromise();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 24,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'One effective chart becomes:',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const _PromiseItem(
              icon: Icons.data_object,
              label: 'Deterministic JSON',
            ),
            const _PromiseItem(
              icon: Icons.table_rows_outlined,
              label: 'Source data',
            ),
            const _PromiseItem(
              icon: Icons.image_outlined,
              label: 'PNG preview',
            ),
            const _PromiseItem(
              icon: Icons.restore_outlined,
              label: 'Fresh chart',
            ),
          ],
        ),
      ),
    );
  }
}

class _PromiseItem extends StatelessWidget {
  const _PromiseItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.detail,
    required this.complete,
  });

  final int number;
  final String title;
  final String detail;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete
            ? colors.primaryContainer.withValues(alpha: 0.45)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: complete ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: complete
                ? colors.primary
                : colors.surfaceContainerHighest,
            foregroundColor: complete
                ? colors.onPrimary
                : colors.onSurfaceVariant,
            child: complete
                ? const Icon(Icons.check, size: 18)
                : Text('$number'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactLibrary extends StatelessWidget {
  const _ArtifactLibrary({
    required this.captures,
    required this.selectedId,
    required this.restoredId,
    required this.busy,
    required this.onSelect,
    required this.onRestore,
    required this.onInspect,
    required this.onCapture,
  });

  final List<_CapturedArtifactEntry> captures;
  final String? selectedId;
  final String? restoredId;
  final bool busy;
  final ValueChanged<_CapturedArtifactEntry> onSelect;
  final VoidCallback onRestore;
  final VoidCallback onInspect;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final selected = captures.any((entry) => entry.artifactId == selectedId);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.collections_bookmark_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Captured charts',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${captures.length} saved in this demo session',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (captures.isNotEmpty)
                  Badge(label: Text('${captures.length}')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: captures.isEmpty
                ? _EmptyPanel(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'No captured charts yet',
                    message:
                        'Capture the current chart to add a portable copy with a thumbnail and raw data.',
                    action: FilledButton.icon(
                      onPressed: onCapture,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Capture first chart'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: captures.length,
                    findItemIndexCallback: (key) {
                      final index = captures.indexWhere(
                        (entry) =>
                            ValueKey('artifact-library-${entry.artifactId}') ==
                            key,
                      );
                      return index < 0 ? null : index;
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = captures[index];
                      return _ArtifactLibraryCard(
                        key: ValueKey('artifact-library-${entry.artifactId}'),
                        entry: entry,
                        selected: entry.artifactId == selectedId,
                        restored: entry.artifactId == restoredId,
                        onTap: () => onSelect(entry),
                      );
                    },
                  ),
          ),
          if (captures.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: selected ? onInspect : null,
                      icon: const Icon(Icons.table_rows_outlined),
                      label: const Text('View data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: selected ? onRestore : null,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore chart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtifactLibraryCard extends StatelessWidget {
  const _ArtifactLibraryCard({
    super.key,
    required this.entry,
    required this.selected,
    required this.restored,
    required this.onTap,
  });

  final _CapturedArtifactEntry entry;
  final bool selected;
  final bool restored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final thumbnailProvider = entry.thumbnailProvider;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.42)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: ValueKey('artifact-thumbnail-${entry.sequence}'),
                width: 96,
                height: 68,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: thumbnailProvider == null
                    ? Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.onSurfaceVariant,
                      )
                    : Image(
                        image: thumbnailProvider,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: colors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _TinyLabel(
                          icon: Icons.schedule,
                          label: entry.capturedTime,
                        ),
                        if (restored)
                          const _TinyLabel(
                            icon: Icons.restore,
                            label: 'Restored',
                          ),
                      ],
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
}

class _TinyLabel extends StatelessWidget {
  const _TinyLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _SurfaceBadge extends StatelessWidget {
  const _SurfaceBadge({required this.restored, required this.label});

  final bool restored;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: restored ? colors.tertiaryContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: restored
              ? colors.onTertiaryContainer
              : colors.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SurfaceFrame extends StatelessWidget {
  const _SurfaceFrame({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class _RawJsonViewer extends StatelessWidget {
  const _RawJsonViewer({required this.json});

  final String json;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: SingleChildScrollView(
      child: SelectableText(
        json,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.45),
      ),
    ),
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError
                ? colors.onErrorContainer
                : colors.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
