// Copyright 2026 Braven Charts - Pie Charts Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Public showcase for categorical contribution charts.
class PieChartsPage extends StatefulWidget {
  const PieChartsPage({super.key});

  @override
  State<PieChartsPage> createState() => _PieChartsPageState();
}

class _PieChartsPageState extends State<PieChartsPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final BravenChartController _chartController = BravenChartController();
  final math.Random _random = math.Random();

  _PieDataset _dataset = _PieDataset.revenue;
  late Map<String, num> _values;
  bool _showLabels = true;
  PieDataLabelPosition _labelPosition = PieDataLabelPosition.outside;
  PieDataLabelContent _labelContent = PieDataLabelContent.categoryAndPercentage;
  PieDataLabelCollisionStrategy _collisionStrategy =
      PieDataLabelCollisionStrategy.shiftAndHide;
  double _minimumShare = 0.03;
  double _startAngle = -90;
  bool _clockwise = true;
  double _radiusFactor = 0.86;
  double _sliceGap = 4;
  double _borderWidth = 1;
  double _selectionExplodeOffset = 10;
  double _cornerRadius = 8;
  double _sliceOpacity = 1;
  bool _showShadow = false;
  bool _showSelectedGlow = true;
  bool _animateSlices = true;
  _PiePalette _palette = _PiePalette.theme;
  _PieCalloutPreset _calloutPreset = _PieCalloutPreset.none;
  _PieTooltipPreset _tooltipPreset = _PieTooltipPreset.theme;
  bool _showLegend = true;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  bool _showTooltips = true;
  String? _selectedCategory;
  ChartDisplayMode _displayMode = ChartDisplayMode.chart;
  ChartTableModel? _tableModel;
  ChartDocumentRevision? _tableRevision;
  ChartArtifact? _capturedArtifact;
  HydratedChartConfiguration? _restoredConfiguration;
  String? _portableJson;
  String? _captureError;
  bool _isCapturing = false;
  bool _showRestoredCopy = false;
  int _tableRefreshAttempts = 0;

  @override
  void initState() {
    super.initState();
    _values = Map<String, num>.of(_dataset.categoryValues);
    _scheduleTableRefresh();
  }

  @override
  void dispose() {
    _optionsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _selectDataset(_PieDataset dataset) {
    if (_dataset == dataset) return;
    setState(() {
      _dataset = dataset;
      _values = Map<String, num>.of(dataset.categoryValues);
      _selectedCategory = null;
      _clearPortableState();
    });
    _chartController.clearPointSelection();
    _scheduleTableRefresh();
  }

  void _regenerateValues() {
    _chartController.clearPointSelection();
    setState(() {
      _selectedCategory = null;
      _clearPortableState();
      _values = {
        for (final entry in _dataset.categoryValues.entries)
          entry.key: math.max(
            1,
            entry.value * (0.72 + _random.nextDouble() * 0.56),
          ),
      };
    });
    _scheduleTableRefresh();
  }

  void _clearPortableState() {
    _capturedArtifact = null;
    _restoredConfiguration = null;
    _portableJson = null;
    _captureError = null;
    _showRestoredCopy = false;
  }

  void _scheduleTableRefresh({bool resetAttempts = true}) {
    if (resetAttempts) _tableRefreshAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshTableFromChart();
    });
  }

  void _refreshTableFromChart() {
    final result = _chartController.extractDocument(
      ChartDocumentExtractOptions(documentId: 'pie-showcase-${_dataset.name}'),
    );
    if (result case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
      final snapshot = result.value;
      final model = ChartTableModel.fromDocument(
        snapshot.document,
        viewState: snapshot.viewState,
      );
      if (!mounted) return;
      setState(() {
        _tableModel = model;
        _tableRevision = snapshot.revision;
      });
      _tableRefreshAttempts = 0;
      return;
    }
    if (_tableRefreshAttempts < 3) {
      _tableRefreshAttempts++;
      _scheduleTableRefresh(resetAttempts: false);
    }
  }

  Future<void> _capturePortableCopy() async {
    if (_isCapturing) return;
    final previousMode = _displayMode;
    if (previousMode == ChartDisplayMode.data) {
      setState(() => _displayMode = ChartDisplayMode.chart);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    final captured = await _chartController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'pie-showcase-${DateTime.now().microsecondsSinceEpoch}',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'pie-showcase-${_dataset.name}',
        ),
        previewOptions: const ChartPreviewOptions(pixelRatio: 0.75),
      ),
    );
    if (!mounted) return;
    if (captured case ChartArtifactFailure<ChartArtifact>()) {
      setState(() {
        _isCapturing = false;
        _captureError =
            '${captured.error.message} Try again after the chart finishes rendering.';
        _displayMode = previousMode;
      });
      return;
    }
    final artifact = (captured as ChartArtifactSuccess<ChartArtifact>).value;
    final encoded = ChartArtifactJsonCodec.encode(artifact);
    if (encoded case ChartArtifactFailure<String>()) {
      setState(() {
        _isCapturing = false;
        _captureError = encoded.error.message;
        _displayMode = previousMode;
      });
      return;
    }
    final json = (encoded as ChartArtifactSuccess<String>).value;
    final hydrated = ChartDocumentHydrator.hydrateJson(json);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _isCapturing = false;
        _captureError = hydrated.error.message;
        _displayMode = previousMode;
      });
      return;
    }
    setState(() {
      _isCapturing = false;
      _capturedArtifact = artifact;
      _portableJson = json;
      _restoredConfiguration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
      _displayMode = previousMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Pie Charts',
      subtitle: 'Explain how categories contribute to one meaningful whole',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Data labels',
        icon: Icons.label_outline,
        children: [
          BoolOption(
            label: 'Show labels',
            value: _showLabels,
            onChanged: (value) => setState(() => _showLabels = value),
            subtitle: 'Keep category meaning next to each contribution',
          ),
          if (_showLabels) ...[
            EnumOption<PieDataLabelPosition>(
              label: 'Position',
              value: _labelPosition,
              values: PieDataLabelPosition.values,
              labelBuilder: _labelPositionName,
              onChanged: (value) => setState(() => _labelPosition = value),
            ),
            EnumOption<PieDataLabelContent>(
              label: 'Content',
              value: _labelContent,
              values: PieDataLabelContent.values,
              labelBuilder: _labelContentName,
              onChanged: (value) => setState(() => _labelContent = value),
            ),
            if (_labelPosition == PieDataLabelPosition.outside)
              EnumOption<PieDataLabelCollisionStrategy>(
                label: 'Collision handling',
                value: _collisionStrategy,
                values: PieDataLabelCollisionStrategy.values,
                labelBuilder: _collisionName,
                onChanged: (value) =>
                    setState(() => _collisionStrategy = value),
              ),
            SliderOption(
              label: 'Minimum share',
              value: _minimumShare * 100,
              min: 0,
              max: 20,
              divisions: 20,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _minimumShare = value / 100),
            ),
            EnumOption<_PieCalloutPreset>(
              label: 'Callout style',
              value: _calloutPreset,
              values: _PieCalloutPreset.values,
              labelBuilder: _calloutPresetName,
              onChanged: (value) => setState(() => _calloutPreset = value),
            ),
          ],
        ],
      ),
      OptionSection(
        title: 'Pie geometry',
        icon: Icons.pie_chart_outline,
        children: [
          SliderOption(
            label: 'Start angle',
            value: _startAngle,
            min: -180,
            max: 180,
            divisions: 24,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _startAngle = value),
          ),
          BoolOption(
            label: 'Clockwise order',
            value: _clockwise,
            onChanged: (value) => setState(() => _clockwise = value),
          ),
          SliderOption(
            label: 'Radius',
            value: _radiusFactor * 100,
            min: 55,
            max: 100,
            divisions: 9,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _radiusFactor = value / 100),
          ),
          SliderOption(
            label: 'Slice gap',
            value: _sliceGap,
            min: 0,
            max: 8,
            divisions: 8,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sliceGap = value),
          ),
          SliderOption(
            label: 'Border width',
            value: _borderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _borderWidth = value),
          ),
          SliderOption(
            label: 'Selected slice offset',
            value: _selectionExplodeOffset,
            min: 0,
            max: 24,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _selectionExplodeOffset = value),
          ),
        ],
      ),
      OptionSection(
        title: 'Slice appearance',
        icon: Icons.palette_outlined,
        children: [
          EnumOption<_PiePalette>(
            label: 'Color palette',
            value: _palette,
            values: _PiePalette.values,
            labelBuilder: _paletteName,
            onChanged: (value) => setState(() => _palette = value),
          ),
          SliderOption(
            label: 'Transparency',
            value: _sliceOpacity * 100,
            min: 25,
            max: 100,
            divisions: 15,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sliceOpacity = value / 100),
          ),
          SliderOption(
            label: 'Rounded corners',
            value: _cornerRadius,
            min: 0,
            max: 20,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _cornerRadius = value),
          ),
          BoolOption(
            label: 'Slice shadow',
            value: _showShadow,
            onChanged: (value) => setState(() => _showShadow = value),
          ),
          BoolOption(
            label: 'Selected slice glow',
            value: _showSelectedGlow,
            onChanged: (value) => setState(() => _showSelectedGlow = value),
          ),
          BoolOption(
            label: 'Animate changes',
            value: _animateSlices,
            onChanged: (value) => setState(() => _animateSlices = value),
            subtitle: 'Regenerate values to replay the radial entrance',
          ),
        ],
      ),
      OptionSection(
        title: 'Legend',
        icon: Icons.view_list_outlined,
        children: [
          BoolOption(
            label: 'Show slice legend',
            value: _showLegend,
            onChanged: (value) => setState(() => _showLegend = value),
            subtitle: 'Legend items select slices; they do not hide data',
          ),
          if (_showLegend) ...[
            EnumOption<LegendPosition>(
              label: 'Position',
              value: _legendPosition,
              values: LegendPosition.values,
              labelBuilder: _legendPositionName,
              onChanged: (value) => setState(() => _legendPosition = value),
            ),
            EnumOption<LegendOrientation>(
              label: 'Orientation',
              value: _legendOrientation,
              values: LegendOrientation.values,
              labelBuilder: _legendOrientationName,
              onChanged: (value) => setState(() => _legendOrientation = value),
            ),
          ],
        ],
      ),
      OptionSection(
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          BoolOption(
            label: 'Show tooltips',
            value: _showTooltips,
            onChanged: (value) => setState(() => _showTooltips = value),
            subtitle: 'Hover or tap a slice for category, value, and share',
          ),
          if (_showTooltips)
            EnumOption<_PieTooltipPreset>(
              label: 'Tooltip style',
              value: _tooltipPreset,
              values: _PieTooltipPreset.values,
              labelBuilder: _tooltipPresetName,
              onChanged: (value) => setState(() => _tooltipPreset = value),
            ),
        ],
      ),
      StandardChartOptions(
        controller: _optionsController,
        showGridOption: false,
        showAxisOption: false,
        showMarkerOption: false,
        showScrollbarOptions: false,
        showLegendOption: false,
        showInteractionOptions: false,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Dataset',
        icon: Icons.refresh,
        children: [
          ActionButton(
            label: 'Regenerate values',
            icon: Icons.casino_outlined,
            onPressed: _regenerateValues,
          ),
        ],
      ),
    ];
  }

  Widget _buildWorkspace() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            return SingleChildScrollView(
              key: const ValueKey('pie-showcase-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDatasetHeader(compact: compact),
                  const SizedBox(height: 8),
                  _buildDatasetSelector(compact: compact),
                  const SizedBox(height: 16),
                  _buildInteractionGuide(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: compact ? 680 : 640,
                    child: ChartCard(
                      key: const ValueKey('pie-showcase-card'),
                      title: _dataset.title,
                      subtitle: _chartSummary(),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDisplayModeSelector(),
                          const SizedBox(height: 8),
                          Expanded(child: _buildDataSurface(compact: compact)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPortableWorkflow(compact: compact),
                  const SizedBox(height: 32),
                  _buildFeatureGuide(),
                  const SizedBox(height: 32),
                  _buildCodeRecipe(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDisplayModeSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<ChartDisplayMode>(
        key: const ValueKey('pie-display-mode'),
        segments: const [
          ButtonSegment(
            value: ChartDisplayMode.chart,
            icon: Icon(Icons.show_chart, size: 18),
            label: Text('Chart'),
          ),
          ButtonSegment(
            value: ChartDisplayMode.data,
            icon: Icon(Icons.table_rows_outlined, size: 18),
            label: Text('Data'),
          ),
          ButtonSegment(
            value: ChartDisplayMode.split,
            icon: Icon(Icons.vertical_split_outlined, size: 18),
            label: Text('Split'),
          ),
        ],
        selected: {_displayMode},
        onSelectionChanged: (selected) {
          setState(() => _displayMode = selected.single);
          if (_tableModel == null) _scheduleTableRefresh();
        },
      ),
    );
  }

  Widget _buildDataSurface({required bool compact}) {
    final chart = _buildLiveChart();
    final table = _buildLiveTable();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final split = _displayMode == ChartDisplayMode.split;
        final showChart = _displayMode != ChartDisplayMode.data;
        final showTable = _displayMode != ChartDisplayMode.chart;
        final splitWidth = (constraints.maxWidth - gap) / 2;
        final splitHeight = (constraints.maxHeight - gap) / 2;

        // Keep both surfaces in stable slots so changing the view never
        // remounts the chart or detaches its controller.
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: split && !compact ? splitWidth : constraints.maxWidth,
              height: split && compact ? splitHeight : constraints.maxHeight,
              child: Offstage(offstage: !showChart, child: chart),
            ),
            Positioned(
              left: split && !compact ? splitWidth + gap : 0,
              top: split && compact ? splitHeight + gap : 0,
              width: split && !compact ? splitWidth : constraints.maxWidth,
              height: split && compact ? splitHeight : constraints.maxHeight,
              child: Offstage(offstage: !showTable, child: table),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveChart() {
    final theme = _buildPieTheme();
    return BravenChartPlus(
      key: const ValueKey('pie-showcase-chart'),
      title: _dataset.chartTitle,
      subtitle: _dataset.chartSubtitle,
      bravenChartController: _chartController,
      showLegend: _showLegend,
      theme: theme,
      interactionConfig: InteractionConfig(
        crosshair: const CrosshairConfig(enabled: false),
        tooltip: TooltipConfig(
          enabled: _showTooltips,
          triggerMode: TooltipTriggerMode.both,
        ),
        enableZoom: false,
        enablePan: false,
        enableSelection: true,
        showFocusBorder: true,
      ),
      onPointTap: _handlePointActivation,
      series: [_buildSeries()],
    );
  }

  Widget _buildLiveTable() {
    final model = _tableModel;
    if (model == null) {
      return const ChartDataTable(isLoading: true);
    }
    return ChartDataTable(
      key: const ValueKey('pie-showcase-table'),
      model: model,
      selectedPointRefs: _chartController.selectedPointRefs,
      csvFileName: 'pie-${_dataset.name}.csv',
      onRowFocused: _focusTablePoints,
      onRowFocusCleared: _chartController.clearPointFocus,
      onRowHoverChanged: (points) => points == null
          ? _chartController.clearPointFocus()
          : _focusTablePoints(points),
      onRowActivated: _selectTablePoints,
    );
  }

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ?? _tableRevision;
    if (revision == null) return;
    _chartController.focusPoints(points, revision: revision);
  }

  void _selectTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ?? _tableRevision;
    if (revision == null) return;
    final selectedPoints = _chartController.selectedPointRefs;
    if (points.isNotEmpty &&
        selectedPoints.length == points.length &&
        selectedPoints.containsAll(points)) {
      _chartController.clearPointSelection();
      setState(() => _selectedCategory = null);
      _scheduleTableRefresh();
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final selected = points.isEmpty ? null : points.first;
      String? category;
      if (selected != null) {
        for (final row in _tableModel?.pieRows ?? const <ChartTablePieRow>[]) {
          if (row.reference == selected) {
            category = row.category;
            break;
          }
        }
      }
      setState(() => _selectedCategory = category);
      _scheduleTableRefresh();
    }
  }

  Widget _buildPortableWorkflow({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final artifact = _capturedArtifact;
    final previewBytes = artifact?.preview?.bytes;
    final captureButton = ElevatedButton.icon(
      key: const ValueKey('capture-pie-artifact'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _isCapturing ? null : _capturePortableCopy,
      icon: _isCapturing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_outlined, size: 18),
      label: Text(_isCapturing ? 'Capturing copy…' : 'Capture portable copy'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPortableHeading(),
                const SizedBox(height: 16),
                captureButton,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPortableHeading()),
                const SizedBox(width: 24),
                captureButton,
              ],
            ),
          if (_captureError != null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.error_outline,
              message: _captureError!,
              color: colors.errorContainer,
              foreground: colors.onErrorContainer,
            ),
          ],
          if (artifact == null && _captureError == null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.info_outline,
              message:
                  'Capture stores the Pie series, current configuration, view state, and a revision-bound PNG preview.',
              color: colors.primaryContainer.withValues(alpha: 0.36),
              foreground: colors.onPrimaryContainer,
            ),
          ],
          if (artifact != null) ...[
            const SizedBox(height: 24),
            _buildCapturedArtifactBody(
              artifact: artifact,
              previewBytes: previewBytes,
              compact: compact,
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const ValueKey('inspect-pie-artifact-json'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.data_object_outlined),
                title: const Text('Inspect canonical JSON'),
                subtitle: Text(
                  '${_portableJson?.length ?? 0} UTF-16 characters',
                ),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _portableJson ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showRestoredCopy && _restoredConfiguration != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.restore, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restored from canonical JSON into a fresh chart runtime',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              key: const ValueKey('restored-pie-artifact'),
              height: compact ? 440 : 420,
              child: _restoredConfiguration!.build(
                key: ValueKey('restored-${artifact?.artifactId}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapturedArtifactBody({
    required ChartArtifact artifact,
    required Uint8List? previewBytes,
    required bool compact,
  }) {
    final colors = Theme.of(context).colorScheme;
    final preview = AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: previewBytes == null
            ? const Center(child: Text('Preview was not available'))
            : Image.memory(
                previewBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: 'Captured pie chart preview',
              ),
      ),
    );
    final details = _buildPortableDetails(artifact);
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [preview, const SizedBox(height: 16), details],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: preview),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: details),
      ],
    );
  }

  Widget _buildPortableHeading() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capture, transport, and restore',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Create a schema-v1 artifact, inspect its real JSON and PNG preview, then hydrate an independent chart from that saved copy.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPortableDetails(ChartArtifact artifact) {
    final colors = Theme.of(context).colorScheme;
    final preview = artifact.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Schema ${artifact.schemaVersion}')),
            const Chip(label: Text('series.pie')),
            const Chip(label: Text('series.pie.style.v2')),
            Chip(
              label: Text(
                preview == null
                    ? 'No PNG preview'
                    : '${preview.widthPixels.toInt()} × ${preview.heightPixels.toInt()} PNG',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${artifact.document.series.single.data.pointCount} transported categories · '
          '${artifact.document.requiredCapabilities.length} required capabilities · '
          '${_portableJson?.length ?? 0} JSON characters',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('restore-pie-artifact'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => setState(() => _showRestoredCopy = true),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Restore captured chart'),
        ),
      ],
    );
  }

  Widget _buildCaptureMessage({
    required IconData icon,
    required String message,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionGuide() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.touch_app_outlined, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory == null
                      ? 'Try slice interaction'
                      : 'Selected: $_selectedCategory',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hover for details. Select a slice or legend item to explode it. '
                  'With chart focus, use arrow keys to move, Enter to select, and Escape to clear.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedCategory != null)
            IconButton(
              tooltip: 'Clear slice selection',
              onPressed: () {
                _chartController.clearPointSelection();
                setState(() => _selectedCategory = null);
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final pointIndex = point.x.round();
    final isSelected = _chartController.selectedPointRefs.contains(
      ChartPointRef(seriesId: seriesId, pointIndex: pointIndex),
    );
    setState(() => _selectedCategory = isSelected ? point.label : null);
  }

  Widget _buildDatasetHeader({required bool compact}) {
    final title = Text(
      'Choose a category story',
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
    final action = ElevatedButton.icon(
      key: const ValueKey('regenerate-pie-values'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _regenerateValues,
      icon: const Icon(Icons.casino_outlined, size: 18),
      label: const Text('Regenerate values'),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 8), action],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        action,
      ],
    );
  }

  Widget _buildDatasetSelector({required bool compact}) {
    const spacing = 12.0;
    if (compact) {
      return SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _PieDataset.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final dataset = _PieDataset.values[index];
            return SizedBox(width: 210, child: _datasetCard(dataset));
          },
        ),
      );
    }

    return Row(
      children: [
        for (final (index, dataset) in _PieDataset.values.indexed) ...[
          if (index > 0) const SizedBox(width: spacing),
          Expanded(child: _datasetCard(dataset)),
        ],
      ],
    );
  }

  Widget _datasetCard(_PieDataset dataset) {
    final colors = Theme.of(context).colorScheme;
    final selected = dataset == _dataset;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Show ${dataset.title}',
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('pie-dataset-${dataset.name}'),
          onTap: () => _selectDataset(dataset),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dataset.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 18, color: colors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dataset.selectorDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built for readable category comparisons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'The renderer keeps category order stable and resolves labels inside the available space.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.donut_large_outlined,
                  title: 'One meaningful whole',
                  description:
                      'Each non-negative value becomes one contribution. Zero values stay in the data but do not draw a slice.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.label_outline,
                  title: 'Labels that make room',
                  description:
                      'Choose inside or outside labels, control their content, and shift or hide labels when space is tight.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.contrast_outlined,
                  title: 'Theme-aware rendering',
                  description:
                      'Palettes, opacity, corners, shadow, selected glow, callouts, tooltips, and legends resolve through the active chart theme.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Selection for every input',
                  description:
                      'Hover, tap, legend controls, arrow keys, and assistive actions resolve the same stable source slice.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.table_rows_outlined,
                  title: 'Category-first data table',
                  description:
                      'Switch to Data or Split for sortable Category, Value, and Share rows with native row copy, dataset copy, and CSV export.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.inventory_2_outlined,
                  title: 'Portable by default',
                  description:
                      'Capture canonical schema-v1 JSON and a revision-bound PNG, then hydrate a fresh chart runtime from that saved document.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCodeRecipe() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Style a pie through the chart theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Insertion order becomes slice order. Keep geometry with the series and reusable presentation defaults in PieChartTheme, LegendStyle, and InteractionTheme.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          );
          final code = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SelectableText(
              "final series = PieChartSeries.fromMap(\n"
              "  id: 'revenue',\n"
              "  unit: 'USD',\n"
              "  values: {\n"
              "    'Subscriptions': 42,\n"
              "    'Services': 31,\n"
              "    'Hardware': 17,\n"
              "  },\n"
              "  dataLabels: PieDataLabelConfig(\n"
              "    position: PieDataLabelPosition.outside,\n"
              "  ),\n"
              ");\n\n"
              "final theme = ChartTheme.light.copyWith(\n"
              "  legendStyle: ChartTheme.light.legendStyle.copyWith(\n"
              "    position: LegendPosition.centerRight,\n"
              "    orientation: LegendOrientation.vertical,\n"
              "  ),\n"
              "  pieChartTheme: const PieChartTheme(\n"
              "    cornerRadius: 10,\n"
              "    selectedElevation: PieElevationStyle(\n"
              "      blurRadius: 12,\n"
              "      spreadRadius: 2,\n"
              "      opacity: 0.5,\n"
              "    ),\n"
              "  ),\n"
              ");\n\n"
              "BravenChartPlus(\n"
              "  series: [series],\n"
              "  theme: theme,\n"
              "  showLegend: true,\n"
              "  onPointTap: (point, seriesId) {\n"
              "    // Respond to the selected source slice.\n"
              "  },\n"
              ");",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [explanation, const SizedBox(height: 24), code],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: explanation),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: code),
            ],
          );
        },
      ),
    );
  }

  PieChartSeries _buildSeries() {
    return PieChartSeries.fromMap(
      id: 'pie-showcase-${_dataset.name}',
      name: _dataset.title,
      unit: _dataset.unit,
      values: _values,
      pieStyle: PieChartStyle(
        startAngleDegrees: _startAngle,
        clockwise: _clockwise,
        radiusFactor: _radiusFactor,
        sliceGap: _sliceGap,
        borderWidth: _borderWidth,
        selectionExplodeOffset: _selectionExplodeOffset,
      ),
      dataLabels: PieDataLabelConfig(
        isVisible: _showLabels,
        position: _labelPosition,
        content: _labelContent,
        minimumShare: _minimumShare,
        collisionStrategy: _collisionStrategy,
      ),
    );
  }

  ChartTheme _buildPieTheme() {
    final base = _optionsController.theme ?? ChartTheme.light;
    final palette = _paletteColors;
    final seriesTheme = palette == null
        ? base.seriesTheme
        : base.seriesTheme.copyWith(colors: palette);
    final calloutStyle = _calloutStyle(base);
    final tooltipStyle = _tooltipStyle(base);
    return base.copyWith(
      seriesTheme: seriesTheme,
      legendStyle: base.legendStyle.copyWith(
        position: _legendPosition,
        orientation: _legendOrientation,
        markerShape: LegendMarkerShape.circle,
        markerSize: 14,
        markerLabelSpacing: 8,
      ),
      interactionTheme: base.interactionTheme.copyWith(
        tooltipStyle: tooltipStyle,
      ),
      pieChartTheme: PieChartTheme(
        opacity: _sliceOpacity,
        cornerRadius: _cornerRadius,
        shadow: _showShadow
            ? const PieElevationStyle(
                color: Color(0x4D1A1A1A),
                blurRadius: 8,
                offset: Offset(0, 4),
                opacity: 0.7,
              )
            : const PieElevationStyle(),
        selectedElevation: _showSelectedGlow
            ? const PieElevationStyle(
                blurRadius: 12,
                spreadRadius: 2,
                opacity: 0.48,
              )
            : const PieElevationStyle(),
        calloutStyle: calloutStyle,
        animationMode: _animateSlices
            ? PieAnimationMode.grow
            : PieAnimationMode.none,
      ),
    );
  }

  List<Color>? get _paletteColors => switch (_palette) {
    _PiePalette.theme => null,
    _PiePalette.ocean => const [
      Color(0xFF006D77),
      Color(0xFF0A9396),
      Color(0xFF48CAE4),
      Color(0xFF90E0EF),
      Color(0xFF023E8A),
      Color(0xFF0077B6),
    ],
    _PiePalette.sunset => const [
      Color(0xFFE63946),
      Color(0xFFF77F00),
      Color(0xFFFCBF49),
      Color(0xFFD62828),
      Color(0xFF9D4EDD),
      Color(0xFF5A189A),
    ],
    _PiePalette.earth => const [
      Color(0xFF386641),
      Color(0xFF6A994E),
      Color(0xFFA7C957),
      Color(0xFFBC6C25),
      Color(0xFFDDA15E),
      Color(0xFF606C38),
    ],
    _PiePalette.monochrome => const [
      Color(0xFF1F2937),
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF6B7280),
      Color(0xFF9CA3AF),
      Color(0xFFD1D5DB),
    ],
  };

  LabelStyle? _calloutStyle(ChartTheme theme) => switch (_calloutPreset) {
    _PieCalloutPreset.none => null,
    _PieCalloutPreset.surface => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.backgroundColor.withValues(alpha: 0.94),
      borderColor: theme.axisStyle.lineColor.withValues(alpha: 0.55),
      borderWidth: 1,
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shadowColor: const Color(0x261A1A1A),
      shadowBlurRadius: 6,
    ),
    _PieCalloutPreset.accent => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.12),
      borderColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.72),
      borderWidth: 1.5,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shadowColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.18),
      shadowBlurRadius: 8,
    ),
  };

  LabelStyle _tooltipStyle(ChartTheme theme) => switch (_tooltipPreset) {
    _PieTooltipPreset.theme => theme.interactionTheme.tooltipStyle,
    _PieTooltipPreset.elevated => theme.interactionTheme.tooltipStyle.copyWith(
      borderRadius: 10,
      borderWidth: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shadowColor: const Color(0x401A1A1A),
      shadowBlurRadius: 12,
    ),
    _PieTooltipPreset.contrast => LabelStyle(
      textStyle: TextStyle(
        color: theme.backgroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          theme.axisStyle.labelStyle.color ?? const Color(0xFF1A1A1A),
      borderColor: theme.backgroundColor.withValues(alpha: 0.72),
      borderWidth: 1,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shadowColor: const Color(0x4D1A1A1A),
      shadowBlurRadius: 8,
    ),
  };

  String _chartSummary() {
    final total = _values.values.fold<double>(
      0,
      (sum, value) => sum + value.toDouble(),
    );
    final formattedTotal = total.toStringAsFixed(total % 1 == 0 ? 0 : 1);
    final labelSummary = _showLabels
        ? '${_labelPositionName(_labelPosition).toLowerCase()} labels'
        : 'labels hidden';
    return '${_values.length} categories · $formattedTotal ${_dataset.unit} total · $labelSummary';
  }

  String _labelPositionName(PieDataLabelPosition value) => switch (value) {
    PieDataLabelPosition.inside => 'Inside slices',
    PieDataLabelPosition.outside => 'Outside with connectors',
  };

  String _labelContentName(PieDataLabelContent value) => switch (value) {
    PieDataLabelContent.category => 'Category',
    PieDataLabelContent.value => 'Value',
    PieDataLabelContent.percentage => 'Percentage',
    PieDataLabelContent.categoryAndValue => 'Category + value',
    PieDataLabelContent.categoryAndPercentage => 'Category + percentage',
    PieDataLabelContent.valueAndPercentage => 'Value + percentage',
    PieDataLabelContent.categoryValueAndPercentage =>
      'Category + value + percentage',
  };

  String _collisionName(PieDataLabelCollisionStrategy value) => switch (value) {
    PieDataLabelCollisionStrategy.none => 'Keep original positions',
    PieDataLabelCollisionStrategy.shift => 'Shift to avoid overlap',
    PieDataLabelCollisionStrategy.shiftAndHide => 'Shift, then hide if needed',
  };

  String _paletteName(_PiePalette value) => switch (value) {
    _PiePalette.theme => 'Chart theme',
    _PiePalette.ocean => 'Ocean',
    _PiePalette.sunset => 'Sunset',
    _PiePalette.earth => 'Earth',
    _PiePalette.monochrome => 'Monochrome',
  };

  String _calloutPresetName(_PieCalloutPreset value) => switch (value) {
    _PieCalloutPreset.none => 'Plain text',
    _PieCalloutPreset.surface => 'Raised surface',
    _PieCalloutPreset.accent => 'Palette accent',
  };

  String _tooltipPresetName(_PieTooltipPreset value) => switch (value) {
    _PieTooltipPreset.theme => 'Chart theme',
    _PieTooltipPreset.elevated => 'Elevated surface',
    _PieTooltipPreset.contrast => 'High contrast',
  };

  String _legendPositionName(LegendPosition value) => switch (value) {
    LegendPosition.topLeft => 'Top left',
    LegendPosition.topCenter => 'Top center',
    LegendPosition.topRight => 'Top right',
    LegendPosition.centerLeft => 'Center left',
    LegendPosition.center => 'Overlay center',
    LegendPosition.centerRight => 'Center right',
    LegendPosition.bottomLeft => 'Bottom left',
    LegendPosition.bottomCenter => 'Bottom center',
    LegendPosition.bottomRight => 'Bottom right',
  };

  String _legendOrientationName(LegendOrientation value) => switch (value) {
    LegendOrientation.horizontal => 'Horizontal',
    LegendOrientation.vertical => 'Vertical',
  };
}

enum _PiePalette { theme, ocean, sunset, earth, monochrome }

enum _PieCalloutPreset { none, surface, accent }

enum _PieTooltipPreset { theme, elevated, contrast }

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
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

enum _PieDataset {
  revenue(
    title: 'Revenue contribution',
    chartTitle: 'Revenue by product',
    chartSubtitle: 'Contribution to total recurring revenue',
    selectorDescription: '5 product categories · balanced shares',
    unit: 'USD',
    categoryValues: {
      'Subscriptions': 42,
      'Services': 28,
      'Hardware': 16,
      'Training': 9,
      'Other': 5,
    },
  ),
  effort(
    title: 'Project effort',
    chartTitle: 'Delivery effort by phase',
    chartSubtitle: 'Hours allocated across the current release',
    selectorDescription: '6 delivery phases · one dominant category',
    unit: 'hours',
    categoryValues: {
      'Build': 46,
      'Discovery': 18,
      'Design': 14,
      'Testing': 12,
      'Launch': 7,
      'Support': 3,
    },
  ),
  support(
    title: 'Support volume',
    chartTitle: 'Requests by topic',
    chartSubtitle: 'Dense labels exercise collision-aware placement',
    selectorDescription: '8 request topics · dense label layout',
    unit: 'tickets',
    categoryValues: {
      'Accounts': 24,
      'Billing': 19,
      'Integrations': 15,
      'Reporting': 12,
      'Mobile': 10,
      'Security': 8,
      'Exports': 7,
      'Other': 5,
    },
  );

  const _PieDataset({
    required this.title,
    required this.chartTitle,
    required this.chartSubtitle,
    required this.selectorDescription,
    required this.unit,
    required this.categoryValues,
  });

  final String title;
  final String chartTitle;
  final String chartSubtitle;
  final String selectorDescription;
  final String unit;
  final Map<String, num> categoryValues;
}
