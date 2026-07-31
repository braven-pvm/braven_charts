import 'dart:convert';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/portable_chart_showcase_generator.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates Chart/Data/Split/Source composition and host actions.
class ChartWorkbenchPage extends StatefulWidget {
  const ChartWorkbenchPage({super.key});

  @override
  State<ChartWorkbenchPage> createState() => _ChartWorkbenchPageState();
}

class _ChartWorkbenchPageState extends State<ChartWorkbenchPage> {
  static final _twoDecimalFormatter = ChartFormatterDescriptor(
    id: 'braven.number.fixed',
    arguments: {'decimals': JsonNumberValue(2)},
  ).toDocument();

  final _chartController = _ShowcaseChartController();
  final _workbenchController = ChartWorkbenchController();
  late PortableShowcaseChartStory _story;
  var _seed = 51001;
  var _captureSequence = 0;
  var _rowLayout = ChartTableRowLayout.wide;
  var _refreshPolicy = ChartTableRefreshPolicy.onDocumentRevision;
  ChartArtifact? _capturedArtifact;
  String? _capturedJson;
  String? _captureError;
  List<ChartArtifactWarning> _captureWarnings = const [];

  @override
  void initState() {
    super.initState();
    _story = PortableChartShowcaseGenerator.generate(
      _seed,
      kind: PortableShowcaseChartKind.mixed,
    );
  }

  @override
  void dispose() {
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  ChartDocumentExtractOptions get _documentOptions =>
      ChartDocumentExtractOptions(
        documentId: 'workbench-${_story.kind.name}-${_story.seed}',
        includeViewState: true,
        yAxisFormatterDescriptors: {'y': _twoDecimalFormatter},
      );

  void _generateDataset() {
    setState(() {
      final previousKind = _story.kind;
      do {
        _story = PortableChartShowcaseGenerator.generate(++_seed);
      } while (_story.kind == previousKind);
      _captureError = null;
      _captureWarnings = const [];
    });
    _refreshAfterChartUpdate();
  }

  void _changeRowLayout(ChartTableRowLayout value) {
    if (_rowLayout == value) return;
    setState(() => _rowLayout = value);
    _refreshAfterChartUpdate();
  }

  void _refreshAfterChartUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _workbenchController.refreshTable();
    });
  }

  void _showTableWarning() {
    _workbenchController.setDisplayMode(ChartDisplayMode.data);
    _chartController.warnNextDocument = true;
    _workbenchController.refreshTable();
  }

  void _showRecoverableFailure() {
    _workbenchController.setDisplayMode(ChartDisplayMode.data);
    _chartController.failNextDocument = true;
    _workbenchController.refreshTable();
  }

  Future<void> _showStaleSnapshot() async {
    _workbenchController.setDisplayMode(ChartDisplayMode.data);
    await _workbenchController.refreshTable();
    if (!mounted) return;
    setState(() {
      _refreshPolicy = ChartTableRefreshPolicy.manual;
      final previousKind = _story.kind;
      do {
        _story = PortableChartShowcaseGenerator.generate(++_seed);
      } while (_story.kind == previousKind);
    });
  }

  Future<void> _capture(ChartWorkbenchHandle handle) async {
    final sequence = ++_captureSequence;
    setState(() {
      _captureError = null;
      _captureWarnings = const [];
    });
    final result = await handle.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'workbench-capture-$sequence',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: _documentOptions,
        provenance: ChartArtifactProvenance(
          values: JsonObjectValue({
            'surface': const JsonStringValue('chart-workbench-showcase'),
            'seed': JsonNumberValue(_story.seed),
            'family': JsonStringValue(_story.kind.name),
          }),
        ),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case ChartArtifactFailure<ChartArtifact>():
        setState(() {
          _captureError = '${result.error.code}: ${result.error.message}';
          _captureWarnings = result.warnings;
        });
      case ChartArtifactSuccess<ChartArtifact>():
        final encoded = ChartArtifactJsonCodec.encode(result.value);
        switch (encoded) {
          case ChartArtifactFailure<String>():
            setState(() {
              _captureError = '${encoded.error.code}: ${encoded.error.message}';
              _captureWarnings = [...result.warnings, ...encoded.warnings];
            });
          case ChartArtifactSuccess<String>():
            setState(() {
              _capturedArtifact = result.value;
              _capturedJson = encoded.value;
              _captureWarnings = [...result.warnings, ...encoded.warnings];
            });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 900;
    return ChartPageLayout(
      title: 'Chart Workbench',
      subtitle:
          'Build one chart, then give users linked Chart, Data, Split, and Source views plus safe product actions',
      actions: [
        if (compactHeader)
          IconButton(
            tooltip: 'Generate another chart',
            onPressed: _generateDataset,
            icon: const Icon(Icons.casino_outlined),
          )
        else
          OutlinedButton.icon(
            onPressed: _generateDataset,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Generate another chart'),
          ),
      ],
      optionsChildren: _buildOptions(),
      chart: _buildShowcase(),
    );
  }

  List<Widget> _buildOptions() {
    final group = ChartWorkbenchScope.maybeControllerOf(context);
    final sharedMode = group?.displayMode ?? _workbenchController.requestedMode;
    final sharedModes =
        group?.availableDisplayModes.toList() ?? ChartDisplayMode.values;
    return [
      OptionSection(
        title: 'Shared presentation',
        icon: Icons.sync_alt,
        children: [
          EnumOption<ChartDisplayMode>(
            label: 'Shared view',
            value: sharedMode,
            values: sharedModes,
            labelBuilder: (value) => switch (value) {
              ChartDisplayMode.chart => 'Chart',
              ChartDisplayMode.data => 'Data',
              ChartDisplayMode.split => 'Split',
              ChartDisplayMode.source => 'Source',
            },
            onChanged: (value) => group == null
                ? _workbenchController.setDisplayMode(value)
                : group.setDisplayMode(value),
          ),
          BoolOption(
            label: 'Show view selector',
            value: group?.showModeSwitcher ?? true,
            subtitle: 'Applies to every Workbench in the current scope',
            onChanged: (value) => group?.setShowModeSwitcher(value),
          ),
        ],
      ),
      OptionSection(
        title: 'Table projection',
        icon: Icons.table_chart_outlined,
        children: [
          EnumOption<ChartTableRowLayout>(
            label: 'Row shape',
            value: _rowLayout,
            values: ChartTableRowLayout.values,
            labelBuilder: (value) => switch (value) {
              ChartTableRowLayout.wide => 'Shared X columns',
              ChartTableRowLayout.long => 'One point per row',
            },
            onChanged: _changeRowLayout,
          ),
          EnumOption<ChartTableRefreshPolicy>(
            label: 'Refresh policy',
            value: _refreshPolicy,
            values: ChartTableRefreshPolicy.values,
            labelBuilder: (value) => switch (value) {
              ChartTableRefreshPolicy.manual => 'Manual after first use',
              ChartTableRefreshPolicy.onModeEntry =>
                'When Data becomes visible',
              ChartTableRefreshPolicy.onDocumentRevision =>
                'After chart revisions',
            },
            onChanged: (value) => setState(() => _refreshPolicy = value),
          ),
          ActionButton(
            label: 'Refresh table snapshot',
            icon: Icons.refresh,
            onPressed: () => _workbenchController.refreshTable(),
          ),
        ],
      ),
      OptionSection(
        title: 'Demo dataset',
        icon: Icons.auto_graph_outlined,
        children: [
          ActionButton(
            label: 'Generate another chart',
            icon: Icons.casino_outlined,
            onPressed: _generateDataset,
          ),
        ],
      ),
      OptionSection(
        title: 'Reliability states',
        icon: Icons.health_and_safety_outlined,
        children: [
          ActionButton(
            label: 'Show table warning',
            icon: Icons.info_outline,
            onPressed: _showTableWarning,
          ),
          ActionButton(
            label: 'Show recoverable failure',
            icon: Icons.warning_amber_rounded,
            onPressed: _showRecoverableFailure,
          ),
          ActionButton(
            label: 'Show stale snapshot',
            icon: Icons.update_outlined,
            onPressed: _showStaleSnapshot,
          ),
        ],
      ),
      const OptionSection(
        title: 'What to try',
        icon: Icons.lightbulb_outline,
        children: [
          InfoBox(
            message:
                'Switch Chart, Data, Split, and Source; copy the effective Dart configuration; select a row; inspect captured JSON; then compare the independent restored charts.',
          ),
        ],
      ),
    ];
  }

  Widget _buildShowcase() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorkbenchJourneyOverview(hasCapture: _capturedArtifact != null),
        const SizedBox(height: 24),
        const _JourneySectionHeader(
          eyebrow: 'LINKED PRESENTATION',
          step: '1',
          title: 'Explore one mounted chart in four ways',
          description:
              'Switch views below. The chart stays mounted, table rows link to exact points, and Source reflects the same effective document.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.sizeOf(context).width < 700 ? 760 : 570,
          child: ChartCard(
            title: _story.title,
            subtitle:
                '${_story.summary} · seed ${_story.seed} · one mounted chart',
            padding: const EdgeInsets.all(8),
            child: BravenChartWorkbench(
              key: const ValueKey('showcase-chart-workbench'),
              chartController: _chartController,
              workbenchController: _workbenchController,
              initialDisplayMode: ChartDisplayMode.split,
              availableDisplayModes: const {
                ChartDisplayMode.chart,
                ChartDisplayMode.data,
                ChartDisplayMode.split,
                ChartDisplayMode.source,
              },
              splitBreakpoint: 760,
              documentOptions: _documentOptions,
              tableOptions: ChartTableOptions(rowLayout: _rowLayout),
              tableRefreshPolicy: _refreshPolicy,
              actionsBuilder: (context, handle) => [
                _PointLinkStatus(controller: handle.chartController),
                FilledButton.icon(
                  key: const ValueKey('workbench-host-action'),
                  onPressed: handle.isExtractingArtifact
                      ? null
                      : () => _capture(handle),
                  icon: handle.isExtractingArtifact
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: Text(
                    handle.isExtractingArtifact
                        ? 'Capturing…'
                        : 'Add to report',
                  ),
                ),
              ],
              contextActionsBuilder: (context, handle, invocation) => [
                ChartContextAction(
                  id: 'showcase.addToReport',
                  label: 'Add to report',
                  icon: Icons.bookmark_add_outlined,
                  shortcutLabel: 'Host action',
                  semanticLabel: 'Add the current chart to the demo report',
                  onSelected: () => _capture(handle),
                ),
              ],
              chartActionButtonBuilder: (context, handle) => ChartOverlayAction(
                id: 'showcase.addToReport',
                tooltip: 'Add chart to report',
                semanticLabel: 'Add the current chart to the demo report',
                icon: Icons.bookmark_add_outlined,
                enabled: !handle.isExtractingArtifact,
                onPressed: () => _capture(handle),
              ),
              chartActionButtonConfig: const ChartOverlayActionButtonConfig(
                iconSize: 18,
              ),
              chartBuilder: (context, controller) => BravenChartPlus(
                key: const ValueKey('workbench-mounted-chart'),
                bravenChartController: controller,
                title: _story.title,
                subtitle: _story.explanation,
                series: _story.series,
                annotations: _story.annotations,
                theme: _story.theme,
                showLegend: _story.showLegend,
                xAxisConfig: _story.xAxisConfig,
                yAxis: _story.yAxis,
                contextMenuConfig: const ChartContextMenuConfig(
                  enableLongPress: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _JourneySectionHeader(
          eyebrow: 'HOST BOUNDARY',
          step: '2',
          title: 'Send the current chart back to your app',
          description:
              'Add to report extracts a portable artifact. Workbench does not save, upload, authorize, or retain it.',
        ),
        const SizedBox(height: 12),
        _ArtifactProofCard(
          artifact: _capturedArtifact,
          encodedJson: _capturedJson,
          error: _captureError,
          warnings: _captureWarnings,
        ),
        const SizedBox(height: 24),
        const _JourneySectionHeader(
          eyebrow: 'INDEPENDENT RUNTIMES',
          step: '3',
          title: 'Restore independent copies and compare changes',
          description:
              'Each hydrated chart gets its own controller; document comparison remains explicit and source-preserving.',
        ),
        const SizedBox(height: 12),
        _HydratedComparisonShowcase(
          chartController: _chartController,
          documentOptions: _documentOptions,
          sourceToken: '${_story.kind.name}-${_story.seed}',
        ),
        const SizedBox(height: 24),
        const _JourneySectionHeader(
          eyebrow: 'ADVANCED PROOF',
          step: '4',
          title: 'Control table freshness for live data',
          description:
              'A bounded stream continues updating while the user controls when the data view refreshes.',
        ),
        const SizedBox(height: 12),
        const _BoundedStreamProof(),
        const SizedBox(height: 24),
        const _WorkbenchCodeReference(),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _HydratedComparisonShowcase extends StatefulWidget {
  const _HydratedComparisonShowcase({
    required this.chartController,
    required this.documentOptions,
    required this.sourceToken,
  });

  final BravenChartController chartController;
  final ChartDocumentExtractOptions documentOptions;
  final String sourceToken;

  @override
  State<_HydratedComparisonShowcase> createState() =>
      _HydratedComparisonShowcaseState();
}

class _HydratedComparisonShowcaseState
    extends State<_HydratedComparisonShowcase> {
  final _tileControllers = List.generate(3, (_) => BravenChartController());
  ChartDocumentRevision? _sourceRevision;
  List<HydratedChartConfiguration>? _configurations;
  ChartComparisonModel? _comparison;
  ChartArtifactError? _comparisonError;
  bool _prepareScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.chartController.addListener(_schedulePreparation);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePreparation());
  }

  @override
  void didUpdateWidget(_HydratedComparisonShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartController != widget.chartController) {
      oldWidget.chartController.removeListener(_schedulePreparation);
      widget.chartController.addListener(_schedulePreparation);
      _sourceRevision = null;
      _schedulePreparation();
    } else if (oldWidget.sourceToken != widget.sourceToken) {
      _sourceRevision = null;
      _schedulePreparation();
    }
  }

  @override
  void dispose() {
    widget.chartController.removeListener(_schedulePreparation);
    for (final controller in _tileControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _schedulePreparation() {
    if (_prepareScheduled) return;
    _prepareScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareScheduled = false;
      if (!mounted) return;
      final extracted = widget.chartController.extractDocument(
        widget.documentOptions,
      );
      switch (extracted) {
        case ChartArtifactSuccess<ChartDocumentSnapshot>():
          if (extracted.value.revision == _sourceRevision) return;
          _prepare(extracted.value);
        case ChartArtifactFailure<ChartDocumentSnapshot>():
          setState(() {
            _configurations = null;
            _comparison = null;
            _comparisonError = extracted.error;
          });
      }
    });
  }

  void _prepare(ChartDocumentSnapshot snapshot) {
    final documents = [
      _scaledDocument(snapshot.document, 'comparison-current', 1),
      _scaledDocument(snapshot.document, 'comparison-plus-five', 1.05),
      _scaledDocument(snapshot.document, 'comparison-minus-eight', 0.92),
    ];
    final configurations = <HydratedChartConfiguration>[];
    for (final document in documents) {
      final hydrated = ChartDocumentHydrator.hydrateDocument(
        document,
        viewState: snapshot.viewState,
      );
      if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
        setState(() {
          _sourceRevision = snapshot.revision;
          _configurations = null;
          _comparison = null;
          _comparisonError = hydrated.error;
        });
        return;
      }
      configurations.add(
        (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value,
      );
    }

    final comparison = ChartComparisonBuilder.compare(
      inputs: [
        ChartComparisonInput(
          inputId: 'current',
          label: 'Current',
          document: documents[0],
          viewState: snapshot.viewState,
        ),
        ChartComparisonInput(
          inputId: 'plus-five',
          label: 'Plan +5%',
          document: documents[1],
          viewState: snapshot.viewState,
        ),
        ChartComparisonInput(
          inputId: 'minus-eight',
          label: 'Plan -8%',
          document: documents[2],
          viewState: snapshot.viewState,
        ),
      ],
      seriesMatches: [
        for (final series in snapshot.document.series)
          ChartSeriesMatch(
            semanticKey: series.id,
            seriesIdByInputId: {
              'current': series.id,
              'plus-five': series.id,
              'minus-eight': series.id,
            },
          ),
      ],
      options: const ChartComparisonOptions(
        baselineInputId: 'current',
        duplicatePolicy: ChartComparisonDuplicatePolicy.byOccurrence,
      ),
    );
    setState(() {
      _sourceRevision = snapshot.revision;
      _configurations = configurations;
      switch (comparison) {
        case ChartArtifactSuccess<ChartComparisonModel>():
          _comparison = comparison.value;
          _comparisonError = null;
        case ChartArtifactFailure<ChartComparisonModel>():
          _comparison = null;
          _comparisonError = comparison.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configurations = _configurations;
    return Card(
      key: const ValueKey('workbench-comparison-proof'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compare portable chart documents',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'The host declares series identity. The package aligns raw document values and calculates optional deltas; each restored chart remains its own runtime.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_comparisonError != null)
              _ComparisonFailure(error: _comparisonError!)
            else if (configurations == null)
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _ComparisonProof(model: _comparison!),
              const SizedBox(height: 16),
              Text(
                'Three independently hydrated charts',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Hide a series in one restored chart. The other two do not change.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 680
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (
                        var index = 0;
                        index < configurations.length;
                        index++
                      )
                        SizedBox(
                          width: width,
                          height: 330,
                          child: _HydratedComparisonTile(
                            key: ValueKey('comparison-tile-$index'),
                            label: switch (index) {
                              0 => 'Restored A · Current',
                              1 => 'Restored B · Plan +5%',
                              _ => 'Restored C · Plan -8%',
                            },
                            index: index,
                            configuration: configurations[index],
                            controller: _tileControllers[index],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonProof extends StatelessWidget {
  const _ComparisonProof({required this.model});

  final ChartComparisonModel model;

  @override
  Widget build(BuildContext context) {
    final aligned = model.rows.where((row) => row.isAligned).length;
    final sampleRows = model.rows
        .where((row) => row.isAligned)
        .take(4)
        .toList();
    final export = ChartComparisonExporter.export(model);
    final derivedColumns = export.columns
        .where((column) => column.isDerived)
        .length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Chip(label: Text('3 documents')),
                Chip(label: Text('$aligned aligned rows')),
                Chip(label: Text('${model.warnings.length} warnings')),
                Chip(label: Text('$derivedColumns derived export columns')),
                OutlinedButton.icon(
                  onPressed: () => _showCsv(context, export.csv),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: const Text('Inspect CSV'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Series')),
                  DataColumn(label: Text('X'), numeric: true),
                  DataColumn(label: Text('Current'), numeric: true),
                  DataColumn(label: Text('Plan +5%'), numeric: true),
                  DataColumn(label: Text('Δ'), numeric: true),
                  DataColumn(label: Text('Plan -8%'), numeric: true),
                  DataColumn(label: Text('Δ'), numeric: true),
                ],
                rows: [
                  for (final row in sampleRows)
                    DataRow(
                      cells: [
                        DataCell(Text(row.semanticKey)),
                        DataCell(Text(_fixed(row.alignmentX))),
                        DataCell(
                          Text(_fixed(row.valuesByInputId['current']?.rawY)),
                        ),
                        DataCell(
                          Text(_fixed(row.valuesByInputId['plus-five']?.rawY)),
                        ),
                        DataCell(
                          Text(
                            _signed(row.deltasByInputId['plus-five']?.absolute),
                          ),
                        ),
                        DataCell(
                          Text(
                            _fixed(row.valuesByInputId['minus-eight']?.rawY),
                          ),
                        ),
                        DataCell(
                          Text(
                            _signed(
                              row.deltasByInputId['minus-eight']?.absolute,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fixed(double? value) => value?.toStringAsFixed(2) ?? '—';

  static String _signed(double? value) {
    if (value == null) return '—';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';
  }

  static Future<void> _showCsv(BuildContext context, String csv) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Source and derived comparison columns'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: SelectableText(
            csv.length > 4000 ? '${csv.substring(0, 4000)}\n…' : csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _HydratedComparisonTile extends StatefulWidget {
  const _HydratedComparisonTile({
    super.key,
    required this.label,
    required this.index,
    required this.configuration,
    required this.controller,
  });

  final String label;
  final int index;
  final HydratedChartConfiguration configuration;
  final BravenChartController controller;

  @override
  State<_HydratedComparisonTile> createState() =>
      _HydratedComparisonTileState();
}

class _HydratedComparisonTileState extends State<_HydratedComparisonTile> {
  @override
  Widget build(BuildContext context) {
    final targetSeries = widget.configuration.series.first;
    final seriesId = targetSeries.id;
    final seriesName = targetSeries.name?.trim().isNotEmpty == true
        ? targetSeries.name!.trim()
        : seriesId;
    final hidden = widget.controller.hiddenSeriesIds.contains(seriesId);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: ValueKey('comparison-tile-toggle-${widget.index}'),
                  onPressed: () {
                    widget.controller.setSeriesVisible(seriesId, hidden);
                    setState(() {});
                  },
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                  ),
                  label: Text(hidden ? 'Show $seriesName' : 'Hide $seriesName'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Text(
                hidden
                    ? '$seriesName is hidden in this restored chart only.'
                    : 'All ${widget.configuration.series.length} series are visible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hidden
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: hidden ? FontWeight.w600 : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: widget.configuration.build(
                key: ValueKey('hydrated-comparison-chart-${widget.index}'),
                bravenChartController: widget.controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonFailure extends StatelessWidget {
  const _ComparisonFailure({required this.error});

  final ChartArtifactError error;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      Icons.error_outline,
      color: Theme.of(context).colorScheme.error,
    ),
    title: const Text('Comparison could not be prepared'),
    subtitle: Text('${error.code}: ${error.message}'),
  );
}

ChartDocument _scaledDocument(
  ChartDocument source,
  String documentId,
  double scale,
) {
  final json = source.toJson();
  json['documentId'] = documentId;
  json['title'] = null;
  json['subtitle'] = null;
  final series = json['series']! as List<Object?>;
  for (final seriesValue in series) {
    final seriesJson = seriesValue! as Map<String, Object?>;
    final data = seriesJson['data']! as Map<String, Object?>;
    if (data['storage'] != 'inlinePoints') continue;
    final points = data['points']! as List<Object?>;
    for (final pointValue in points) {
      final point = pointValue! as Map<String, Object?>;
      final y = point['y'];
      if (y is num) point['y'] = y.toDouble() * scale;
    }
  }
  return ChartDocument.fromJson(json);
}

class _WorkbenchJourneyOverview extends StatelessWidget {
  const _WorkbenchJourneyOverview({required this.hasCapture});

  final bool hasCapture;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer.withValues(alpha: 0.42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hub_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One chart, four linked views, one host-owned result',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BravenChartPlus renders the chart. BravenChartWorkbench wraps that same mounted chart when users also need its exact data, generated source, or an app-specific action.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final decisions = [
                  const _WorkbenchDecision(
                    icon: Icons.show_chart,
                    title: 'Use BravenChartPlus directly',
                    description: 'Your screen only needs an interactive chart.',
                  ),
                  const _WorkbenchDecision(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Add a Workbench',
                    description:
                        'Users need Chart, Data, Split, or Source—or must send the current chart into your workflow.',
                  ),
                ];
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      for (
                        var index = 0;
                        index < decisions.length;
                        index++
                      ) ...[
                        decisions[index],
                        if (index != decisions.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: decisions[0]),
                    const SizedBox(width: 12),
                    Expanded(child: decisions[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const _WorkbenchFlow(),
            const SizedBox(height: 12),
            _WorkbenchOutcome(hasCapture: hasCapture, colors: colors),
          ],
        ),
      ),
    );
  }
}

class _WorkbenchDecision extends StatelessWidget {
  const _WorkbenchDecision({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchFlow extends StatelessWidget {
  const _WorkbenchFlow();

  static const _steps = [
    (
      icon: Icons.show_chart,
      title: 'Your chart',
      detail: 'One mounted BravenChartPlus',
    ),
    (
      icon: Icons.view_week_outlined,
      title: 'Linked views',
      detail: 'Chart · Data · Split · Source',
    ),
    (
      icon: Icons.extension_outlined,
      title: 'Host action',
      detail: 'For example, Add to report',
    ),
    (
      icon: Icons.inventory_2_outlined,
      title: 'Your application',
      detail: 'Owns storage, policy, and navigation',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isVertical = constraints.maxWidth < 760;
      final children = <Widget>[];
      for (var index = 0; index < _steps.length; index++) {
        final step = _steps[index];
        children.add(
          isVertical
              ? _WorkbenchFlowNode(
                  icon: step.icon,
                  title: step.title,
                  detail: step.detail,
                )
              : Expanded(
                  child: _WorkbenchFlowNode(
                    icon: step.icon,
                    title: step.title,
                    detail: step.detail,
                  ),
                ),
        );
        if (index != _steps.length - 1) {
          children.add(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isVertical ? 0 : 8,
                vertical: isVertical ? 4 : 0,
              ),
              child: Icon(
                isVertical
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
            ),
          );
        }
      }
      return isVertical
          ? Column(children: children)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            );
    },
  );
}

class _WorkbenchFlowNode extends StatelessWidget {
  const _WorkbenchFlowNode({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title. $detail',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchOutcome extends StatelessWidget {
  const _WorkbenchOutcome({required this.hasCapture, required this.colors});

  final bool hasCapture;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        hasCapture ? Icons.check_circle_outline : Icons.touch_app_outlined,
        size: 18,
        color: colors.primary,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          key: const ValueKey('workbench-outcome-status'),
          hasCapture
              ? 'Portable result ready below. The Workbench returned it; this demo host chose what to do next.'
              : 'Try it below: switch views, select a data row, then choose Add to report. Nothing is saved until the host handles the returned artifact.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}

class _JourneySectionHeader extends StatelessWidget {
  const _JourneySectionHeader({
    required this.eyebrow,
    required this.step,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            step,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointLinkStatus extends StatelessWidget {
  const _PointLinkStatus({required this.controller});

  final BravenChartController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      final focused = controller.focusedPointRefs.length;
      final selected = controller.selectedPointRefs.length;
      if (focused == 0 && selected == 0) {
        return const SizedBox.shrink(
          key: ValueKey('workbench-point-link-status'),
        );
      }
      final label = selected > 0
          ? '$selected selected'
          : focused > 0
          ? '$focused focused'
          : '';
      return Chip(
        key: const ValueKey('workbench-point-link-status'),
        avatar: Icon(
          selected > 0
              ? Icons.check_circle_outline
              : focused > 0
              ? Icons.center_focus_strong_outlined
              : Icons.link_outlined,
          size: 16,
        ),
        label: Text(label),
      );
    },
  );
}

class _BoundedStreamProof extends StatefulWidget {
  const _BoundedStreamProof();

  @override
  State<_BoundedStreamProof> createState() => _BoundedStreamProofState();
}

class _BoundedStreamProofState extends State<_BoundedStreamProof> {
  static const _bufferLimit = 12;

  final _chartController = BravenChartController();
  final _workbenchController = ChartWorkbenchController();
  final _liveController = LiveStreamController(
    seriesId: 'bounded-sensor',
    maxPoints: _bufferLimit,
    autoScroll: false,
  );
  late final Listenable _metricsListenable;
  var _nextSample = 0;
  String? _contextCaptureStatus;

  @override
  void initState() {
    super.initState();
    _metricsListenable = Listenable.merge([
      _workbenchController,
      _liveController,
    ]);
    _appendSamples(8);
  }

  @override
  void dispose() {
    _workbenchController.dispose();
    _chartController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  void _appendSamples(int count) {
    for (var index = 0; index < count; index++) {
      final sample = _nextSample++;
      _liveController.addPoint(
        ChartDataPoint(
          x: sample.toDouble(),
          y: 110 + math.sin(sample / 2) * 18 + (sample % 3) * 3,
        ),
      );
    }
  }

  Future<void> _refreshTable() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await _workbenchController.refreshTable();
      if (!_workbenchController.tableIsStale) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _captureSnapshot(
    ChartWorkbenchHandle handle, {
    required String sourceLabel,
  }) async {
    final result = await handle.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'stream-context-${_nextSample - 1}',
        includePreview: false,
      ),
    );
    if (!mounted) return;
    setState(() {
      _contextCaptureStatus = switch (result) {
        ChartArtifactSuccess<ChartArtifact>() =>
          '$sourceLabel capture · ${result.value.document.series.length} series',
        ChartArtifactFailure<ChartArtifact>() =>
          '${result.error.code}: ${result.error.message}',
      };
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bounded stream, deliberate table snapshot',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'The live controller retains 12 samples. Manual refresh keeps the table stable until the user requests a new snapshot.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _metricsListenable,
            builder: (context, _) => Semantics(
              liveRegion: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    key: const ValueKey('stream-live-count'),
                    avatar: const Icon(Icons.sensors_outlined, size: 16),
                    label: Text(
                      '${_liveController.pointCount} / $_bufferLimit live samples',
                    ),
                  ),
                  Chip(
                    key: const ValueKey('stream-table-count'),
                    avatar: const Icon(Icons.table_rows_outlined, size: 16),
                    label: Text(
                      '${_workbenchController.tableModel?.rowCount ?? 0} table rows',
                    ),
                  ),
                  if (_workbenchController.tableIsStale)
                    const Chip(
                      avatar: Icon(Icons.update_outlined, size: 16),
                      label: Text('Snapshot is stale'),
                    ),
                  if (_contextCaptureStatus != null)
                    Chip(
                      key: const ValueKey('stream-context-capture-status'),
                      avatar: const Icon(Icons.task_alt_outlined, size: 16),
                      label: Text(_contextCaptureStatus!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxWidth < 700 ? 720 : 470,
              child: BravenChartWorkbench(
                key: const ValueKey('stream-chart-workbench'),
                chartController: _chartController,
                workbenchController: _workbenchController,
                initialDisplayMode: ChartDisplayMode.split,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                splitBreakpoint: 760,
                // This proof isolates snapshot freshness. The primary
                // workbench above demonstrates revision-safe row linking.
                linkTableRowsToChart: false,
                tableRefreshPolicy: ChartTableRefreshPolicy.manual,
                documentOptions: const ChartDocumentExtractOptions(
                  documentId: 'bounded-stream-snapshot',
                  includeViewState: true,
                ),
                actionsBuilder: (context, handle) => [
                  OutlinedButton.icon(
                    key: const ValueKey('stream-add-samples'),
                    onPressed: () => _appendSamples(5),
                    icon: const Icon(Icons.add_chart_outlined, size: 18),
                    label: const Text('Add 5 samples'),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('stream-refresh-table'),
                    onPressed: handle.isExtractingDocument
                        ? null
                        : _refreshTable,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      handle.isExtractingDocument
                          ? 'Refreshing table…'
                          : 'Refresh table',
                    ),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                    ),
                  ),
                ],
                contextActionsBuilder: (context, handle, invocation) => [
                  ChartContextAction(
                    id: 'showcase.captureStreamSnapshot',
                    label: 'Capture stream snapshot',
                    icon: Icons.camera_alt_outlined,
                    onSelected: () => _captureSnapshot(
                      handle,
                      sourceLabel: invocation.source.name,
                    ),
                  ),
                ],
                chartActionButtonBuilder: (context, handle) =>
                    ChartOverlayAction(
                      id: 'showcase.captureStreamSnapshot',
                      tooltip: 'Capture stream snapshot',
                      icon: Icons.camera_alt_outlined,
                      enabled: !handle.isExtractingArtifact,
                      onPressed: () =>
                          _captureSnapshot(handle, sourceLabel: 'button'),
                    ),
                chartBuilder: (context, controller) => BravenChartPlus(
                  bravenChartController: controller,
                  liveStreamController: _liveController,
                  title: 'Rolling sensor buffer',
                  subtitle: 'New samples do not silently rewrite the table',
                  showLegend: false,
                  interactionConfig: const InteractionConfig(
                    enableSelection: false,
                  ),
                  contextMenuConfig: const ChartContextMenuConfig(
                    enableLongPress: true,
                  ),
                  xAxisConfig: const XAxisConfig(label: 'Sample'),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Signal',
                  ),
                  series: const [
                    LineChartSeries(
                      id: 'bounded-sensor',
                      name: 'Sensor',
                      unit: 'units',
                      points: [],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArtifactProofCard extends StatelessWidget {
  const _ArtifactProofCard({
    required this.artifact,
    required this.encodedJson,
    required this.error,
    required this.warnings,
  });

  final ChartArtifact? artifact;
  final String? encodedJson;
  final String? error;
  final List<ChartArtifactWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final artifact = this.artifact;
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: error != null
            ? Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error!)),
                ],
              )
            : artifact == null
            ? const _EmptyArtifactProof()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final previewBytes = artifact.preview?.bytes;
                  final details = _ArtifactDetails(
                    artifact: artifact,
                    encodedJson: encodedJson ?? '',
                    warnings: warnings,
                  );
                  if (constraints.maxWidth < 700) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (previewBytes != null)
                          SizedBox(
                            height: 180,
                            child: Image.memory(
                              previewBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        if (previewBytes != null) const SizedBox(height: 16),
                        details,
                      ],
                    );
                  }
                  return SizedBox(
                    height: 240,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: previewBytes == null
                              ? const Center(
                                  child: Text('No inline preview available'),
                                )
                              : Image.memory(previewBytes, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: details),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyArtifactProof extends StatelessWidget {
  const _EmptyArtifactProof();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.bookmark_add_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No host action result yet'),
            SizedBox(height: 4),
            Text(
              'Choose Add to report above. This demo host will show the portable document and preview returned by the workbench.',
            ),
          ],
        ),
      ),
    ],
  );
}

class _ArtifactDetails extends StatelessWidget {
  const _ArtifactDetails({
    required this.artifact,
    required this.encodedJson,
    required this.warnings,
  });

  final ChartArtifact artifact;
  final String encodedJson;
  final List<ChartArtifactWarning> warnings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Portable copy returned to the host',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        'The workbench captured the effective document and PNG. This page decides where the artifact goes next.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text(artifact.artifactId)),
          Chip(label: Text('${artifact.document.series.length} series')),
          if (artifact.viewState?.selectedPointRefs.isNotEmpty == true)
            Chip(
              avatar: const Icon(Icons.link_outlined, size: 16),
              label: Text(
                '${artifact.viewState!.selectedPointRefs.length} selected points',
              ),
            ),
          Chip(label: Text('${utf8.encode(encodedJson).length} JSON bytes')),
          Chip(
            avatar: const Icon(Icons.image_outlined, size: 16),
            label: Text(
              artifact.preview == null ? 'No preview' : 'Preview attached',
            ),
          ),
          Chip(
            avatar: Icon(
              warnings.isEmpty
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              size: 16,
            ),
            label: Text(
              warnings.isEmpty ? 'No warnings' : '${warnings.length} warnings',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const ValueKey('inspect-artifact-button'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => _ArtifactInspectorDialog(
            artifact: artifact,
            encodedJson: encodedJson,
            warnings: warnings,
          ),
        ),
        icon: const Icon(Icons.code_outlined, size: 18),
        label: const Text('Inspect JSON and diagnostics'),
      ),
    ],
  );
}

class _ArtifactInspectorDialog extends StatelessWidget {
  const _ArtifactInspectorDialog({
    required this.artifact,
    required this.encodedJson,
    required this.warnings,
  });

  final ChartArtifact artifact;
  final String encodedJson;
  final List<ChartArtifactWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final documentHash = ChartArtifactCanonicalizer.documentHash(
      artifact.document,
    );
    final previewHash = artifact.preview?.documentHash;
    final hashMatches = previewHash == null || previewHash == documentHash;
    return AlertDialog(
      title: const Text('Inspect portable artifact'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Document JSON'),
                  Tab(text: 'Diagnostics'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          encodedJson,
                          key: const ValueKey('artifact-raw-json'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    ListView(
                      children: [
                        _ArtifactDiagnosticTile(
                          label: 'Artifact identity',
                          value: artifact.artifactId,
                        ),
                        _ArtifactDiagnosticTile(
                          label: 'Document identity',
                          value: artifact.document.documentId,
                        ),
                        _ArtifactDiagnosticTile(
                          label: 'Captured data',
                          value:
                              '${artifact.document.series.length} series · ${artifact.document.pointCount} points',
                        ),
                        _ArtifactDiagnosticTile(
                          label: 'Canonical JSON',
                          value: '${utf8.encode(encodedJson).length} bytes',
                        ),
                        _ArtifactDiagnosticTile(
                          label: 'Preview integrity',
                          value: artifact.preview == null
                              ? 'No preview requested'
                              : hashMatches
                              ? 'Hash verified'
                              : 'Hash mismatch',
                          icon: artifact.preview == null
                              ? Icons.image_not_supported_outlined
                              : hashMatches
                              ? Icons.verified_outlined
                              : Icons.error_outline,
                        ),
                        _ArtifactDiagnosticTile(
                          label: 'Warnings',
                          value: warnings.isEmpty
                              ? 'No warnings'
                              : warnings
                                    .map(
                                      (warning) =>
                                          '${warning.code}: ${warning.message}',
                                    )
                                    .join('\n'),
                          icon: warnings.isEmpty
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close inspector'),
        ),
      ],
    );
  }
}

class _ArtifactDiagnosticTile extends StatelessWidget {
  const _ArtifactDiagnosticTile({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    subtitle: SelectableText(value),
  );
}

class _ShowcaseChartController extends BravenChartController {
  bool failNextDocument = false;
  bool warnNextDocument = false;

  @override
  ChartArtifactResult<ChartDocumentSnapshot> extractDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    if (failNextDocument) {
      failNextDocument = false;
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.tableProjectionFailed,
          message:
              'The demo could not prepare the latest table. Retry to use current chart data.',
        ),
      );
    }
    final result = super.extractDocument(options);
    if (!warnNextDocument) return result;
    warnNextDocument = false;
    return switch (result) {
      ChartArtifactSuccess<ChartDocumentSnapshot>() => ChartArtifactSuccess(
        value: result.value,
        warnings: const [
          ChartArtifactWarning(
            code: 'showcase_safe_fallback',
            message:
                'The demo used a safe display fallback. Raw values remain unchanged.',
          ),
        ],
      ),
      ChartArtifactFailure<ChartDocumentSnapshot>() => result,
    };
  }
}

class _WorkbenchCodeReference extends StatefulWidget {
  const _WorkbenchCodeReference();

  @override
  State<_WorkbenchCodeReference> createState() =>
      _WorkbenchCodeReferenceState();
}

class _WorkbenchCodeReferenceState extends State<_WorkbenchCodeReference> {
  static const _snippets = [
    (
      label: 'Compose linked views',
      source: '''final workbenchController = ChartWorkbenchController();

final workbench = BravenChartWorkbench(
  workbenchController: workbenchController,
  initialDisplayMode: ChartDisplayMode.split,
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
  chartBuilder: (context, chartController) => BravenChartPlus(
    bravenChartController: chartController,
    series: series,
  ),
);''',
    ),
    (
      label: 'Return an artifact',
      source: '''BravenChartWorkbench(
  chartBuilder: (context, chartController) => BravenChartPlus(
    bravenChartController: chartController,
    series: series,
  ),
  actionsBuilder: (context, handle) => [
    FilledButton.icon(
      icon: const Icon(Icons.bookmark_add_outlined),
      label: const Text('Add to report'),
      onPressed: () async {
        final result = await handle.extractArtifact(options);
        switch (result) {
          case ChartArtifactSuccess<ChartArtifact>():
            await reportStore.add(result.value);
          case ChartArtifactFailure<ChartArtifact>():
            showArtifactError(result.error);
        }
      },
    ),
  ],
);''',
    ),
  ];

  var _selectedSnippet = 0;
  var _wrapLines = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snippet = _snippets[_selectedSnippet];
    return Card(
      key: const ValueKey('workbench-code-reference'),
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Workbench without handing it storage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The supplied chart controller links every view. The stable handle returns an artifact; your application decides whether and where to persist it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<int>(
                      key: const ValueKey('workbench-code-snippet-selector'),
                      showSelectedIcon: false,
                      segments: [
                        for (var index = 0; index < _snippets.length; index++)
                          ButtonSegment<int>(
                            value: index,
                            label: Text(_snippets[index].label),
                          ),
                      ],
                      selected: {_selectedSnippet},
                      onSelectionChanged: (selection) =>
                          setState(() => _selectedSnippet = selection.single),
                    ),
                    Text(
                      'Dart · ${snippet.label}',
                      style: theme.textTheme.labelLarge,
                    ),
                    IconButton(
                      tooltip: _wrapLines
                          ? 'Disable line wrapping'
                          : 'Wrap lines',
                      onPressed: () => setState(() => _wrapLines = !_wrapLines),
                      icon: Icon(
                        _wrapLines ? Icons.wrap_text : Icons.horizontal_rule,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: const ValueKey('copy-workbench-code'),
                      onPressed: () => _copyCode(context, snippet),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copy code'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          SizedBox(
            height: 390,
            child: ChartCodeBlock(
              code: snippet.source,
              wrapLines: _wrapLines,
              semanticLabel: '${snippet.label} Dart example',
              surfaceKey: const ValueKey('workbench-usage-code-window'),
              codeKey: const ValueKey('workbench-usage-code'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(
    BuildContext context,
    ({String label, String source}) snippet,
  ) async {
    await Clipboard.setData(ClipboardData(text: snippet.source));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text('${snippet.label} code copied')));
  }
}
