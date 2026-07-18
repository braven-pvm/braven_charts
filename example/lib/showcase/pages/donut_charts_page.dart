// Copyright 2026 Braven Charts - Donut Charts Showcase
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/options_panel.dart';
import '../widgets/radial_legend_value_card.dart';
import '../widgets/standard_options.dart';

/// Public showcase for first-class Donut geometry and portable center content.
class DonutChartsPage extends StatefulWidget {
  const DonutChartsPage({super.key});

  @override
  State<DonutChartsPage> createState() => _DonutChartsPageState();
}

class _DonutChartsPageState extends State<DonutChartsPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();

  _DonutStory _story = _DonutStory.contribution;
  double _innerRadiusFactor = 0.58;
  double _sweepAngleDegrees = 360;
  double _startAngleDegrees = -90;
  double _radiusFactor = 0.86;
  double _sliceGap = 3;
  double _cornerRadius = 8;
  PieAnimationMode _animationMode = PieAnimationMode.grow;
  bool _clockwise = true;
  bool _showLabels = true;
  bool _showLegend = true;
  _DonutLegendContent _legendContent = _DonutLegendContent.standard;
  bool _showCenterContent = true;
  bool _groupSmallSlices = false;
  double _groupingMinimumShare = 0.07;
  DonutCenterValueMode _centerValueMode = DonutCenterValueMode.selectedOrTotal;
  _DonutCenterStyle _centerStyle = _DonutCenterStyle.theme;
  ChartDisplayMode _displayMode = ChartDisplayMode.split;
  ChartArtifact? _capturedArtifact;
  HydratedChartConfiguration? _restoredConfiguration;
  String? _portableJson;
  String? _captureError;
  String? _selectedCategory;
  bool _isCapturing = false;
  bool _showRestoredCopy = false;

  @override
  void dispose() {
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Donut Charts',
      subtitle:
          'Compare category contributions around a configurable center opening',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return SingleChildScrollView(
          key: const ValueKey('donut-showcase-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStorySelector(compact: compact),
              const SizedBox(height: 16),
              _buildSliceNotice(),
              const SizedBox(height: 16),
              SizedBox(
                height: compact ? 760 : 680,
                child: _buildChartCard(compact: compact),
              ),
              const SizedBox(height: 32),
              _buildPortableWorkflow(compact: compact),
              const SizedBox(height: 32),
              _buildFeatureGuide(compact: compact),
              const SizedBox(height: 32),
              _buildCodeRecipe(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStorySelector({required bool compact}) {
    final theme = Theme.of(context);
    final availableWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = compact ? availableWidth : 220.0;
    return Semantics(
      container: true,
      label: 'Choose a Donut geometry story',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final story in _DonutStory.values)
            SizedBox(
              width: cardWidth,
              child: Material(
                color: story == _story
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: story == _story
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('donut-story-${story.name}'),
                  onTap: () => _selectStory(story),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 76),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(story.icon, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  story.description,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (story == _story)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliceNotice() {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.donut_large_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(_sliceNoticeText)),
          ],
        ),
      ),
    );
  }

  String get _sliceNoticeText {
    if (_selectedCategory == null) {
      return _groupSmallSlices
          ? 'Small categories render as one Other slice, while the data table keeps every original row. Select Other or any grouped row to see the shared selection.'
          : 'Select a slice, legend item, or table row. The center follows the same durable selection, then returns to the total when selection clears.';
    }
    if (_groupSmallSlices && _selectedCategory == 'Other') {
      RadialCategorySlice? grouped;
      for (final slice in _buildSeries().visibleSlices) {
        if (slice.isGrouped) {
          grouped = slice;
          break;
        }
      }
      if (grouped != null) {
        return 'Selected: Other. One visible slice now selects all ${grouped.sourcePointIndices.length} original source rows through the controller.';
      }
    }
    return 'Selected: $_selectedCategory. The chart, table, controller, and center now share this category identity.';
  }

  Widget _buildChartCard({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('donut-showcase-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartHeading(theme),
                  const SizedBox(height: 8),
                  _buildChartMetrics(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChartHeading(theme)),
                  const SizedBox(width: 16),
                  Flexible(child: _buildChartMetrics()),
                ],
              ),
            const SizedBox(height: 8),
            _buildDisplayModeSelector(),
            const SizedBox(height: 8),
            Expanded(child: _buildDataSurface(compact: compact)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeading(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _story.chartTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _story.chartDescription,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildChartMetrics() => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: [
      _MetricPill(label: '${(_innerRadiusFactor * 100).round()}% center'),
      _MetricPill(label: '${_sweepAngleDegrees.round()}° sweep'),
      _MetricPill(label: _centerModeName(_centerValueMode)),
      _MetricPill(label: '${_animationModeName(_animationMode)} in'),
      if (_groupSmallSlices) const _MetricPill(label: 'Grouped sources'),
    ],
  );

  Widget _buildDisplayModeSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<ChartDisplayMode>(
        key: const ValueKey('donut-display-mode'),
        segments: const [
          ButtonSegment(
            value: ChartDisplayMode.chart,
            icon: Icon(Icons.donut_large_outlined, size: 18),
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
          final mode = selected.single;
          setState(() => _displayMode = mode);
          _workbenchController.setDisplayMode(mode);
        },
      ),
    );
  }

  Widget _buildDataSurface({required bool compact}) {
    return BravenChartWorkbench(
      chartController: _chartController,
      workbenchController: _workbenchController,
      initialDisplayMode: _displayMode,
      showModeSwitcher: false,
      splitBreakpoint: 1,
      splitAxis: compact ? Axis.vertical : Axis.horizontal,
      splitGap: 8,
      minimumChartPaneExtent: compact ? 240 : 360,
      minimumTablePaneExtent: compact ? 240 : 420,
      maximumAutoTablePaneExtent: 620,
      autoFitTablePane: true,
      isSplitResizable: true,
      tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
      onTableRowFocused: _focusTablePoints,
      onTableRowFocusCleared: _chartController.clearPointFocus,
      onTableRowHoverChanged: (points) => points == null
          ? _chartController.clearPointFocus()
          : _focusTablePoints(points),
      onTableRowActivated: _selectTablePoints,
      chartBuilder: (context, controller) => _buildLiveChart(controller),
    );
  }

  Widget _buildLiveChart(BravenChartController controller) {
    return BravenChartPlus(
      key: const ValueKey('donut-showcase-chart'),
      title: _story.chartTitle,
      subtitle: _story.chartDescription,
      bravenChartController: controller,
      showLegend: _showLegend,
      radialLegendItemBuilder: _legendContent == _DonutLegendContent.valueCards
          ? _buildValueCardLegendItem
          : null,
      theme: ChartTheme.light,
      interactionConfig: const InteractionConfig(
        crosshair: CrosshairConfig(enabled: false),
        tooltip: TooltipConfig(
          enabled: true,
          triggerMode: TooltipTriggerMode.both,
        ),
        enableZoom: false,
        enablePan: false,
        enableSelection: true,
        showFocusBorder: false,
      ),
      onPointTap: _handlePointActivation,
      series: [_buildSeries()],
    );
  }

  Widget _buildValueCardLegendItem(
    BuildContext context,
    RadialLegendItemData item,
  ) => RadialLegendValueCard(
    key: ValueKey('donut-custom-legend-item-${item.visibleIndex}'),
    item: item,
  );

  DonutChartSeries _buildSeries() {
    return DonutChartSeries.fromMap(
      id: 'donut-${_story.name}',
      name: _story.seriesName,
      unit: _story.unit,
      values: _story.values,
      radiusValues: _story.radiusValues,
      sliceRadiusConfig: _story.radiusValues.isEmpty
          ? null
          : const RadialSliceRadiusConfig(
              minimumFactor: 0.42,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
              unit: 'k users',
            ),
      sliceGroupingConfig: _groupSmallSlices
          ? RadialSliceGroupingConfig(
              minimumShare: _groupingMinimumShare,
              label: 'Other',
            )
          : null,
      donutStyle: DonutChartStyle(
        innerRadiusFactor: _innerRadiusFactor,
        sweepAngleDegrees: _sweepAngleDegrees,
        startAngleDegrees: _startAngleDegrees,
        clockwise: _clockwise,
        radiusFactor: _radiusFactor,
        sliceGap: _sliceGap,
        borderWidth: 1,
        borderColorMode: PieBorderColorMode.slice,
        borderLightnessShift: -0.18,
        selectionExplodeOffset: 10,
        cornerRadius: _cornerRadius,
        cornerTreatment: PieCornerTreatment.roundAll,
        animationMode: _animationMode,
        gradient: const PieGradientStyle(
          type: PieGradientType.radial,
          startLightnessShift: 0.14,
          endLightnessShift: -0.08,
        ),
      ),
      centerContent: DonutCenterContent(
        isVisible: _showCenterContent,
        label: switch (_centerValueMode) {
          DonutCenterValueMode.total => 'Total',
          DonutCenterValueMode.custom => 'Status',
          DonutCenterValueMode.selectedValue ||
          DonutCenterValueMode.selectedOrTotal => null,
        },
        valueMode: _centerValueMode,
        customValue: _centerValueMode == DonutCenterValueMode.custom
            ? 'On track'
            : null,
        labelStyle: _centerLabelStyle,
        valueStyle: _centerValueStyle,
      ),
      dataLabels: PieDataLabelConfig(
        isVisible: _showLabels,
        position: PieDataLabelPosition.outside,
        content: PieDataLabelContent.categoryAndPercentage,
        outsideOffset: 4,
        minimumShare: 0.04,
        collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
      ),
    );
  }

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    _chartController.focusPoints(points, revision: revision);
  }

  void _selectTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    final selectedPoints = _chartController.selectedPointRefs;
    final targetPoints = _expandedVisibleSliceRefs(points);
    if (targetPoints.isNotEmpty &&
        selectedPoints.length == targetPoints.length &&
        selectedPoints.containsAll(targetPoints)) {
      _chartController.clearPointSelection();
      setState(() => _selectedCategory = null);
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final selected = points.firstOrNull;
      final category = selected == null
          ? null
          : _buildSeries()
                .visibleSliceForSourcePointIndex(selected.pointIndex)
                ?.point
                .label;
      setState(() => _selectedCategory = category);
    }
  }

  Set<ChartPointRef> _expandedVisibleSliceRefs(List<ChartPointRef> points) {
    final series = _buildSeries();
    final expanded = <ChartPointRef>{};
    for (final ref in points) {
      final slice = series.visibleSliceForSourcePointIndex(ref.pointIndex);
      if (slice == null) {
        expanded.add(ref);
        continue;
      }
      expanded.addAll([
        for (final pointIndex in slice.sourcePointIndices)
          ChartPointRef(seriesId: ref.seriesId, pointIndex: pointIndex),
      ]);
    }
    return expanded;
  }

  void _setGroupingEnabled(bool value) {
    _chartController.clearPointSelection();
    setState(() {
      _groupSmallSlices = value;
      _selectedCategory = null;
      _clearPortableState();
    });
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final reference = ChartPointRef(
      seriesId: seriesId,
      pointIndex: point.x.round(),
    );
    final isSelected = _chartController.selectedPointRefs.contains(reference);
    setState(() => _selectedCategory = isSelected ? point.label : null);
  }

  void _clearPortableState() {
    _capturedArtifact = null;
    _restoredConfiguration = null;
    _portableJson = null;
    _captureError = null;
    _showRestoredCopy = false;
  }

  Future<void> _capturePortableCopy() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    final captured = await _chartController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'donut-showcase-${DateTime.now().microsecondsSinceEpoch}',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'donut-${_story.name}',
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
      });
      return;
    }
    final artifact = (captured as ChartArtifactSuccess<ChartArtifact>).value;
    final encoded = ChartArtifactJsonCodec.encode(artifact);
    if (encoded case ChartArtifactFailure<String>()) {
      setState(() {
        _isCapturing = false;
        _captureError = encoded.error.message;
      });
      return;
    }
    final json = (encoded as ChartArtifactSuccess<String>).value;
    final hydrated = ChartDocumentHydrator.hydrateJson(json);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _isCapturing = false;
        _captureError = hydrated.error.message;
      });
      return;
    }
    setState(() {
      _isCapturing = false;
      _capturedArtifact = artifact;
      _portableJson = json;
      _restoredConfiguration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    });
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Donut geometry',
        icon: Icons.donut_large_outlined,
        children: [
          SliderOption(
            label: 'Inner radius',
            value: _innerRadiusFactor * 100,
            min: 20,
            max: 82,
            divisions: 31,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _innerRadiusFactor = value / 100),
          ),
          SliderOption(
            label: 'Sweep angle',
            value: _sweepAngleDegrees,
            min: 90,
            max: 360,
            divisions: 18,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _sweepAngleDegrees = value),
          ),
          SliderOption(
            label: 'Start angle',
            value: _startAngleDegrees,
            min: -180,
            max: 180,
            divisions: 24,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _startAngleDegrees = value),
          ),
          BoolOption(
            label: 'Clockwise order',
            value: _clockwise,
            onChanged: (value) => setState(() => _clockwise = value),
          ),
          SliderOption(
            label: 'Outer radius',
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
            label: 'Rounded corners',
            value: _cornerRadius,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _cornerRadius = value),
          ),
        ],
      ),
      OptionSection(
        title: 'Motion',
        icon: Icons.animation_outlined,
        children: [
          EnumOption<PieAnimationMode>(
            key: const ValueKey('donut-animation-mode'),
            label: 'Entrance',
            value: _animationMode,
            values: PieAnimationMode.values,
            labelBuilder: _animationModeName,
            onChanged: _setAnimationMode,
            subtitle: 'Grow, reveal around the ring, fade, or render instantly',
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('replay-donut-entrance'),
              onPressed: _animationMode == PieAnimationMode.none
                  ? null
                  : _chartController.replayRadialEntrance,
              icon: const Icon(Icons.replay_outlined, size: 18),
              label: const Text('Replay entrance'),
            ),
          ),
        ],
      ),
      OptionSection(
        title: 'Center content',
        icon: Icons.center_focus_strong_outlined,
        children: [
          BoolOption(
            label: 'Show center content',
            value: _showCenterContent,
            onChanged: (value) => setState(() => _showCenterContent = value),
            subtitle: 'Portable text included in previews and artifacts',
          ),
          if (_showCenterContent) ...[
            EnumOption<DonutCenterValueMode>(
              label: 'Value source',
              value: _centerValueMode,
              values: DonutCenterValueMode.values,
              labelBuilder: _centerModeName,
              onChanged: (value) => setState(() => _centerValueMode = value),
            ),
            EnumOption<_DonutCenterStyle>(
              label: 'Center style',
              value: _centerStyle,
              values: _DonutCenterStyle.values,
              labelBuilder: (value) => switch (value) {
                _DonutCenterStyle.theme => 'Theme default',
                _DonutCenterStyle.compact => 'Compact',
                _DonutCenterStyle.accent => 'Accent',
              },
              onChanged: (value) => setState(() => _centerStyle = value),
            ),
          ],
        ],
      ),
      OptionSection(
        title: 'Small categories',
        icon: Icons.call_merge_outlined,
        children: [
          BoolOption(
            key: const ValueKey('donut-group-small-slices'),
            label: 'Group small slices',
            value: _groupSmallSlices,
            onChanged: _story == _DonutStory.reach
                ? (_) {}
                : _setGroupingEnabled,
            subtitle: _story == _DonutStory.reach
                ? 'Variable radii need an explicit second-metric aggregation policy'
                : 'Render one Other slice while preserving every source row',
          ),
          if (_groupSmallSlices)
            SliderOption(
              key: const ValueKey('donut-grouping-threshold'),
              label: 'Share threshold',
              value: _groupingMinimumShare * 100,
              min: 1,
              max: 15,
              divisions: 14,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) {
                _chartController.clearPointSelection();
                setState(() {
                  _groupingMinimumShare = value / 100;
                  _selectedCategory = null;
                  _clearPortableState();
                });
              },
            ),
        ],
      ),
      OptionSection(
        title: 'Chart content',
        icon: Icons.visibility_outlined,
        children: [
          BoolOption(
            label: 'Show labels',
            value: _showLabels,
            onChanged: (value) => setState(() => _showLabels = value),
          ),
          BoolOption(
            label: 'Show legend',
            value: _showLegend,
            onChanged: (value) => setState(() => _showLegend = value),
          ),
          if (_showLegend)
            EnumOption<_DonutLegendContent>(
              key: const ValueKey('donut-legend-content'),
              label: 'Legend content',
              value: _legendContent,
              values: _DonutLegendContent.values,
              labelBuilder: _legendContentName,
              onChanged: (value) => setState(() => _legendContent = value),
            ),
        ],
      ),
    ];
  }

  Widget _buildPortableWorkflow({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final artifact = _capturedArtifact;
    final previewBytes = artifact?.preview?.bytes;
    final captureButton = ElevatedButton.icon(
      key: const ValueKey('capture-donut-artifact'),
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
                  'Capture stores Donut geometry, center content, data, selection state, and a revision-bound PNG preview.',
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
                key: const ValueKey('inspect-donut-artifact-json'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.data_object_outlined),
                title: const Text('Inspect canonical JSON'),
                subtitle: Text('${_portableJson?.length ?? 0} characters'),
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
              key: const ValueKey('restored-donut-artifact'),
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
          'Save the real Donut as schema-v1 JSON with a PNG preview, then hydrate an independent chart from that portable document.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
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
                semanticLabel: 'Captured donut chart preview',
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
            const Chip(label: Text('series.donut')),
            const Chip(label: Text('series.donut.style.v1')),
            if (artifact.document.requiredCapabilities.contains(
              'series.donut.center-content.v1',
            ))
              const Chip(label: Text('series.donut.center-content.v1')),
            if (artifact.document.requiredCapabilities.contains(
              'series.donut.variable-radius.v1',
            ))
              const Chip(label: Text('series.donut.variable-radius.v1')),
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
          '${artifact.document.requiredCapabilities.length} capabilities · '
          '${_portableJson?.length ?? 0} JSON characters',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('restore-donut-artifact'),
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

  Widget _buildFeatureGuide({required bool compact}) {
    final features = const [
      _DonutFeature(
        icon: Icons.vertical_split_outlined,
        title: 'Chart, data, or split',
        description:
            'One document drives the Donut and its native category, value, radius, and share table.',
      ),
      _DonutFeature(
        icon: Icons.center_focus_strong_outlined,
        title: 'A meaningful center',
        description:
            'Show totals, selected values, fallback totals, or portable custom text without a widget builder.',
      ),
      _DonutFeature(
        icon: Icons.hub_outlined,
        title: 'One selection identity',
        description:
            'Slices, legends, tables, controllers, and restored charts resolve the same ChartPointRef.',
      ),
      _DonutFeature(
        icon: Icons.view_list_outlined,
        title: 'Host-built legend items',
        description:
            'Replace every visible legend item with a Flutter widget while the package retains responsive layout, selection, and semantics.',
      ),
      _DonutFeature(
        icon: Icons.call_merge_outlined,
        title: 'Group without losing detail',
        description:
            'Small sources can render as Other while tables, exports, selection callbacks, and controller state retain every original point.',
      ),
      _DonutFeature(
        icon: Icons.inventory_2_outlined,
        title: 'Ready to travel',
        description:
            'Canonical JSON carries geometry, styling, center content, data, and a revision-bound PNG preview.',
      ),
    ];
    final columns = compact ? 1 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built for product workflows',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Donut keeps the category contract of Pie while adding a measured center and annular geometry.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 128,
          children: [for (final feature in features) _FeatureTile(feature)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with one portable series',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'The same public model works in direct Dart configuration, AI tool input, tables, and artifacts.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SelectableText('''DonutChartSeries.fromMap(
  id: 'revenue-share',
  unit: 'USD',
  values: {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 20,
    'Training': 4,
    'Support': 3,
  },
  sliceGroupingConfig: RadialSliceGroupingConfig(
    minimumShare: 0.05,
    label: 'Other',
  ),
  donutStyle: DonutChartStyle(innerRadiusFactor: 0.58),
  centerContent: DonutCenterContent(
    label: 'Revenue',
    valueMode: DonutCenterValueMode.selectedOrTotal,
  ),
)''', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _selectStory(_DonutStory story) {
    _chartController.clearPointSelection();
    setState(() {
      _story = story;
      _selectedCategory = null;
      _clearPortableState();
      switch (story) {
        case _DonutStory.contribution:
          _innerRadiusFactor = 0.58;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.86;
          _sliceGap = 3;
          _cornerRadius = 8;
          _animationMode = PieAnimationMode.grow;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerStyle = _DonutCenterStyle.theme;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = false;
        case _DonutStory.progress:
          _innerRadiusFactor = 0.68;
          _sweepAngleDegrees = 280;
          _startAngleDegrees = 130;
          _radiusFactor = 0.9;
          _sliceGap = 2;
          _cornerRadius = 12;
          _animationMode = PieAnimationMode.sweep;
          _centerValueMode = DonutCenterValueMode.custom;
          _centerStyle = _DonutCenterStyle.accent;
          _legendContent = _DonutLegendContent.valueCards;
          _groupSmallSlices = false;
        case _DonutStory.reach:
          _innerRadiusFactor = 0.3;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.88;
          _sliceGap = 4;
          _cornerRadius = 10;
          _animationMode = PieAnimationMode.fade;
          _centerValueMode = DonutCenterValueMode.total;
          _centerStyle = _DonutCenterStyle.compact;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = false;
        case _DonutStory.grouping:
          _innerRadiusFactor = 0.58;
          _sweepAngleDegrees = 360;
          _startAngleDegrees = -90;
          _radiusFactor = 0.88;
          _sliceGap = 3;
          _cornerRadius = 8;
          _animationMode = PieAnimationMode.sweep;
          _centerValueMode = DonutCenterValueMode.selectedOrTotal;
          _centerStyle = _DonutCenterStyle.theme;
          _legendContent = _DonutLegendContent.standard;
          _groupSmallSlices = true;
          _groupingMinimumShare = 0.07;
      }
    });
  }

  String _centerModeName(DonutCenterValueMode mode) => switch (mode) {
    DonutCenterValueMode.total => 'Total',
    DonutCenterValueMode.selectedValue => 'Selected value',
    DonutCenterValueMode.selectedOrTotal => 'Selected or total',
    DonutCenterValueMode.custom => 'Custom text',
  };

  String _animationModeName(PieAnimationMode mode) => switch (mode) {
    PieAnimationMode.none => 'No animation',
    PieAnimationMode.grow => 'Grow',
    PieAnimationMode.sweep => 'Sweep',
    PieAnimationMode.fade => 'Fade',
  };

  String _legendContentName(_DonutLegendContent value) => switch (value) {
    _DonutLegendContent.standard => 'Standard details',
    _DonutLegendContent.valueCards => 'Custom value cards',
  };

  void _setAnimationMode(PieAnimationMode mode) {
    setState(() => _animationMode = mode);
  }

  LabelStyle? get _centerLabelStyle => switch (_centerStyle) {
    _DonutCenterStyle.theme => null,
    _DonutCenterStyle.compact => const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 10),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
    _DonutCenterStyle.accent => const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF5B55A5), fontSize: 11),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
  };

  LabelStyle? get _centerValueStyle => switch (_centerStyle) {
    _DonutCenterStyle.theme => null,
    _DonutCenterStyle.compact => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.zero,
    ),
    _DonutCenterStyle.accent => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF4F46E5),
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0x0F4F46E5),
      borderColor: Color(0x334F46E5),
      borderWidth: 1,
      borderRadius: 10,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  };
}

enum _DonutStory { contribution, progress, reach, grouping }

enum _DonutCenterStyle { theme, compact, accent }

enum _DonutLegendContent { standard, valueCards }

extension on _DonutStory {
  String get label => switch (this) {
    _DonutStory.contribution => 'Contribution ring',
    _DonutStory.progress => 'Partial sweep',
    _DonutStory.reach => 'Variable radius',
    _DonutStory.grouping => 'Grouped sources',
  };

  String get description => switch (this) {
    _DonutStory.contribution => 'A complete ring for category shares',
    _DonutStory.progress => 'A controlled angular span and opening',
    _DonutStory.reach => 'A second metric controls outer radius',
    _DonutStory.grouping => 'Small sources combine without losing rows',
  };

  IconData get icon => switch (this) {
    _DonutStory.contribution => Icons.donut_large_outlined,
    _DonutStory.progress => Icons.speed_outlined,
    _DonutStory.reach => Icons.radar_outlined,
    _DonutStory.grouping => Icons.call_merge_outlined,
  };

  String get chartTitle => switch (this) {
    _DonutStory.contribution => 'Revenue by product',
    _DonutStory.progress => 'Delivery mix',
    _DonutStory.reach => 'Campaign contribution and reach',
    _DonutStory.grouping => 'Support requests by channel',
  };

  String get chartDescription => switch (this) {
    _DonutStory.contribution =>
      'Five products contribute to total recurring revenue',
    _DonutStory.progress =>
      'The same category contract rendered across a 280° sweep',
    _DonutStory.reach =>
      'Angle shows contribution; outer radius shows audience reach',
    _DonutStory.grouping =>
      'Small channels render as Other while source data stays intact',
  };

  String get seriesName => switch (this) {
    _DonutStory.contribution => 'Revenue',
    _DonutStory.progress => 'Delivery',
    _DonutStory.reach => 'Campaigns',
    _DonutStory.grouping => 'Requests',
  };

  String get unit => switch (this) {
    _DonutStory.contribution => 'USD',
    _DonutStory.progress => 'hours',
    _DonutStory.reach => 'leads',
    _DonutStory.grouping => 'tickets',
  };

  Map<String, num> get values => switch (this) {
    _DonutStory.contribution => const {
      'Subscriptions': 42,
      'Services': 28,
      'Hardware': 16,
      'Training': 9,
      'Other': 5,
    },
    _DonutStory.progress => const {
      'Build': 46,
      'Discovery': 18,
      'Design': 14,
      'Testing': 12,
      'Launch': 7,
      'Support': 3,
    },
    _DonutStory.reach => const {
      'Search': 31,
      'Social': 24,
      'Partners': 19,
      'Events': 15,
      'Email': 11,
    },
    _DonutStory.grouping => const {
      'Portal': 64,
      'Phone': 12,
      'Partners': 9,
      'Email': 6,
      'Chat': 4,
      'Events': 3,
      'Other source': 2,
    },
  };

  Map<String, num> get radiusValues => switch (this) {
    _DonutStory.contribution ||
    _DonutStory.progress ||
    _DonutStory.grouping => const {},
    _DonutStory.reach => const {
      'Search': 82,
      'Social': 54,
      'Partners': 68,
      'Events': 37,
      'Email': 46,
    },
  };
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _DonutFeature {
  const _DonutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(this.feature);

  final _DonutFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
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
