import 'dart:convert';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _WorkbenchDataset { recovery, intervals, distribution }

/// Demonstrates the package-owned Chart/Data/Split composition and host actions.
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
  var _dataset = _WorkbenchDataset.recovery;
  var _generation = 1;
  var _captureSequence = 0;
  var _rowLayout = ChartTableRowLayout.wide;
  var _refreshPolicy = ChartTableRefreshPolicy.onDocumentRevision;
  ChartArtifact? _capturedArtifact;
  String? _capturedJson;
  String? _captureError;
  List<ChartArtifactWarning> _captureWarnings = const [];

  @override
  void dispose() {
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  ChartDocumentExtractOptions get _documentOptions =>
      ChartDocumentExtractOptions(
        documentId: 'workbench-${_dataset.name}-$_generation',
        includeViewState: true,
        yAxisFormatterDescriptors: {'y': _twoDecimalFormatter},
      );

  void _generateDataset() {
    setState(() {
      _generation += 1;
      _dataset = _WorkbenchDataset
          .values[(_dataset.index + 1) % _WorkbenchDataset.values.length];
      _captureError = null;
      _captureWarnings = const [];
    });
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
      _generation += 1;
      _dataset = _WorkbenchDataset
          .values[(_dataset.index + 1) % _WorkbenchDataset.values.length];
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
            'dataset': JsonStringValue(_dataset.name),
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
    return ChartPageLayout(
      title: 'Chart Workbench',
      subtitle:
          'Explore native data views, linked points, portable capture, restoration, and explicit document comparison',
      optionsChildren: _buildOptions(),
      chart: _buildShowcase(),
    );
  }

  List<Widget> _buildOptions() => [
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
            ChartTableRefreshPolicy.onModeEntry => 'When Data becomes visible',
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
          label: 'Generate another dataset',
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
              'Switch Chart, Data, and Split; select a row; inspect captured JSON; try recoverable table states; then compare the independent restored charts.',
        ),
      ],
    ),
  ];

  Widget _buildShowcase() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeatureStrip(hasCapture: _capturedArtifact != null),
        const SizedBox(height: 16),
        const _PointLinkingHint(),
        const SizedBox(height: 16),
        SizedBox(
          height: 570,
          child: ChartCard(
            title: _datasetTitle,
            subtitle:
                '$_datasetDescription · generation $_generation · one mounted chart',
            padding: const EdgeInsets.all(8),
            child: BravenChartWorkbench(
              key: const ValueKey('showcase-chart-workbench'),
              chartController: _chartController,
              workbenchController: _workbenchController,
              initialDisplayMode: ChartDisplayMode.split,
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
              chartBuilder: (context, controller) => BravenChartPlus(
                key: const ValueKey('workbench-mounted-chart'),
                bravenChartController: controller,
                title: _datasetTitle,
                subtitle: _datasetDescription,
                series: _series,
                annotations: [
                  ThresholdAnnotation(
                    id: 'workbench-reference',
                    axis: AnnotationAxis.y,
                    value: _referenceValue,
                    label: 'Reference',
                  ),
                ],
                xAxisConfig: const XAxisConfig(
                  label: 'Sample',
                  min: 0,
                  max: 15,
                ),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Value',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ArtifactProofCard(
          artifact: _capturedArtifact,
          encodedJson: _capturedJson,
          error: _captureError,
          warnings: _captureWarnings,
        ),
        const SizedBox(height: 16),
        const _BoundedStreamProof(),
        const SizedBox(height: 16),
        _HydratedComparisonShowcase(controller: _workbenchController),
        const SizedBox(height: 16),
        const _UsageCard(),
        const SizedBox(height: 16),
      ],
    ),
  );

  String get _datasetTitle => switch (_dataset) {
    _WorkbenchDataset.recovery => 'Recovery response',
    _WorkbenchDataset.intervals => 'Interval comparison',
    _WorkbenchDataset.distribution => 'Sample distribution',
  };

  String get _datasetDescription => switch (_dataset) {
    _WorkbenchDataset.recovery => 'Line and area series over a shared X axis',
    _WorkbenchDataset.intervals => 'Grouped bars for observed and target work',
    _WorkbenchDataset.distribution => 'Scatter samples with a reference trend',
  };

  double get _referenceValue => switch (_dataset) {
    _WorkbenchDataset.recovery => 125,
    _WorkbenchDataset.intervals => 110,
    _WorkbenchDataset.distribution => 95,
  };

  List<ChartSeries> get _series {
    final phase = _generation * 0.37;
    List<ChartDataPoint> points(double base, double amplitude, double offset) =>
        List.generate(16, (index) {
          final wave = math.sin(index / 2.4 + phase + offset) * amplitude;
          final trend = (_generation % 4 - 1.5) * index * 0.35;
          return ChartDataPoint(x: index.toDouble(), y: base + wave + trend);
        });

    return switch (_dataset) {
      _WorkbenchDataset.recovery => [
        AreaChartSeries(
          id: 'load',
          name: 'Training load',
          unit: 'AU',
          color: const Color(0xFF4F46E5),
          points: points(128, 24, 0),
          interpolation: LineInterpolation.monotone,
          fillOpacity: 0.18,
        ),
        LineChartSeries(
          id: 'readiness',
          name: 'Readiness',
          unit: 'AU',
          color: const Color(0xFF059669),
          points: points(105, 15, 1.1),
          interpolation: LineInterpolation.monotone,
          showDataPointMarkers: true,
        ),
      ],
      _WorkbenchDataset.intervals => [
        BarChartSeries(
          id: 'observed',
          name: 'Observed',
          unit: 'kJ',
          color: const Color(0xFF2563EB),
          points: points(112, 18, 0),
          barWidthPercent: 0.62,
        ),
        BarChartSeries(
          id: 'target',
          name: 'Target',
          unit: 'kJ',
          color: const Color(0xFFF59E0B),
          points: points(104, 10, 1.4),
          barWidthPercent: 0.62,
        ),
      ],
      _WorkbenchDataset.distribution => [
        ScatterChartSeries(
          id: 'observed',
          name: 'Observed',
          unit: 'ms',
          color: const Color(0xFF7C3AED),
          points: points(96, 22, 0.6),
          markerRadius: 4,
        ),
        LineChartSeries(
          id: 'trend',
          name: 'Trend',
          unit: 'ms',
          color: const Color(0xFFDC2626),
          points: points(98, 9, 0),
          interpolation: LineInterpolation.bezier,
        ),
      ],
    };
  }
}

class _HydratedComparisonShowcase extends StatefulWidget {
  const _HydratedComparisonShowcase({required this.controller});

  final ChartWorkbenchController controller;

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
    widget.controller.addListener(_schedulePreparation);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePreparation());
  }

  @override
  void didUpdateWidget(_HydratedComparisonShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_schedulePreparation);
      widget.controller.addListener(_schedulePreparation);
      _schedulePreparation();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedulePreparation);
    for (final controller in _tileControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _schedulePreparation() {
    final snapshot = widget.controller.tableSnapshot;
    if (snapshot == null ||
        snapshot.revision == _sourceRevision ||
        _prepareScheduled) {
      return;
    }
    _prepareScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareScheduled = false;
      if (!mounted) return;
      final current = widget.controller.tableSnapshot;
      if (current == null || current.revision == _sourceRevision) return;
      _prepare(current);
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

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.hasCapture});

  final bool hasCapture;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 840 ? 3 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _FeatureCard(
              width: width,
              step: '1',
              icon: Icons.view_week_outlined,
              title: 'Choose a view',
              description:
                  'Chart, native data table, or both—without remounting.',
            ),
            _FeatureCard(
              width: width,
              step: '2',
              icon: Icons.link_outlined,
              title: 'Link rows to points',
              description:
                  'Focus or select a row to highlight its exact chart points.',
            ),
            _FeatureCard(
              width: width,
              step: '3',
              icon: hasCapture
                  ? Icons.check_circle_outline
                  : Icons.extension_outlined,
              title: hasCapture ? 'Portable copy ready' : 'Run a host action',
              description: 'Capture JSON and a PNG without owning persistence.',
              complete: hasCapture,
            ),
          ],
        );
      },
    );
  }
}

class _PointLinkingHint extends StatelessWidget {
  const _PointLinkingHint();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.ads_click_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Try linked chart and table navigation'),
                  SizedBox(height: 4),
                  Text(
                    'Click a data row to keep its points selected in both the chart and table. Keyboard focus previews them; Enter selects them. In the shared-X table, one row links every populated series at that X value.',
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    this.complete = false,
  });

  final double width;
  final String step;
  final IconData icon;
  final String title;
  final String description;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: complete
              ? colors.primaryContainer
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: complete ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: complete
                    ? colors.primary
                    : colors.secondaryContainer,
                foregroundColor: complete
                    ? colors.onPrimary
                    : colors.onSecondaryContainer,
                child: Text(step),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
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
                chartBuilder: (context, controller) => BravenChartPlus(
                  bravenChartController: controller,
                  liveStreamController: _liveController,
                  title: 'Rolling sensor buffer',
                  subtitle: 'New samples do not silently rewrite the table',
                  showLegend: false,
                  interactionConfig: const InteractionConfig(
                    enableSelection: false,
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

class _UsageCard extends StatelessWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use the workbench without coupling storage',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Build the chart with the supplied controller. Add host actions through the stable handle, then persist the returned artifact wherever your application chooses.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SelectableText(
              'BravenChartWorkbench(\n'
              '  initialDisplayMode: ChartDisplayMode.split,\n'
              '  tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,\n'
              '  chartBuilder: (context, controller) => BravenChartPlus(\n'
              '    bravenChartController: controller,\n'
              '    series: series,\n'
              '  ),\n'
              '  // Table rows focus/select matching chart points by default.\n'
              '  actionsBuilder: (context, handle) => [\n'
              '    FilledButton(\n'
              '      onPressed: () => save(handle.extractArtifact(options)),\n'
              "      child: const Text('Add to report'),\n"
              '    ),\n'
              '  ],\n'
              ');',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
