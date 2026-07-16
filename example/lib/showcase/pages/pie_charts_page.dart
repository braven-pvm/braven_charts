// Copyright 2026 Braven Charts - Pie Charts Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

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
  double _sliceGap = 2;
  double _borderWidth = 1;
  double _selectionExplodeOffset = 10;
  bool _showLegend = true;
  bool _showTooltips = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _values = Map<String, num>.of(_dataset.categoryValues);
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
    });
    _chartController.clearPointSelection();
  }

  void _regenerateValues() {
    _chartController.clearPointSelection();
    setState(() {
      _selectedCategory = null;
      _values = {
        for (final entry in _dataset.categoryValues.entries)
          entry.key: math.max(
            1,
            entry.value * (0.72 + _random.nextDouble() * 0.56),
          ),
      };
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
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          BoolOption(
            label: 'Show slice legend',
            value: _showLegend,
            onChanged: (value) => setState(() => _showLegend = value),
            subtitle: 'Legend items select slices; they do not hide data',
          ),
          BoolOption(
            label: 'Show tooltips',
            value: _showTooltips,
            onChanged: (value) => setState(() => _showTooltips = value),
            subtitle: 'Hover or tap a slice for category, value, and share',
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
                    height: compact ? 600 : 620,
                    child: ChartCard(
                      key: const ValueKey('pie-showcase-card'),
                      title: _dataset.title,
                      subtitle: _chartSummary(),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: BravenChartPlus(
                        key: const ValueKey('pie-showcase-chart'),
                        title: _dataset.chartTitle,
                        subtitle: _dataset.chartSubtitle,
                        bravenChartController: _chartController,
                        showLegend: _showLegend,
                        theme: _optionsController.theme,
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
                      ),
                    ),
                  ),
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
                      'Slice colors, borders, connectors, and text follow the active Braven chart theme, including dark and high contrast.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Selection for every input',
                  description:
                      'Hover, tap, legend controls, arrow keys, and assistive actions resolve the same stable source slice.',
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
                'Create a pie from category values',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Insertion order becomes slice order. Geometry and labels live on the series; tooltips, selection, legend controls, and keyboard input are built in.',
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
              "BravenChartPlus(\n"
              "  series: [series],\n"
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
}

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
