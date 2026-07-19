// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Public, renderer-backed guide for axis-based Polar Column charts.
class PolarColumnPage extends StatefulWidget {
  const PolarColumnPage({super.key});

  @override
  State<PolarColumnPage> createState() => _PolarColumnPageState();
}

class _PolarColumnPageState extends State<PolarColumnPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final math.Random _random = math.Random(47);

  _PolarPresentation _presentation = _PolarPresentation.standard;
  late Map<String, num> _values;
  int _categoryCount = 8;
  double _startAngle = -90;
  double _sweepAngle = 360;
  bool _clockwise = true;
  double _innerRadius = 0;
  double _outerRadius = 0.84;
  double _innerPadding = 0.12;
  double _outerPadding = 0.04;
  PolarRadialScaleMode _scaleMode = PolarRadialScaleMode.linear;
  int _tickCount = 5;
  bool _showAngularLabels = true;
  bool _showAngularGrid = true;
  bool _showRadialLabels = true;
  bool _showRadialGrid = true;
  bool _showValues = true;
  double _cornerRadius = 4;
  double _opacity = 0.94;
  String? _selectedCategory;

  static const _standardValues = <String, num>{
    'Search': 86,
    'Social': 58,
    'Partners': 72,
    'Email': 44,
    'Events': 65,
    'Direct': 92,
    'Referral': 54,
    'Other': 36,
  };

  static const _roseValues = <String, num>{
    'Jan': 42,
    'Feb': 58,
    'Mar': 76,
    'Apr': 63,
    'May': 88,
    'Jun': 54,
    'Jul': 97,
    'Aug': 82,
    'Sep': 69,
    'Oct': 74,
    'Nov': 49,
    'Dec': 61,
  };

  static const _partialValues = <String, num>{
    'Discover': 84,
    'Evaluate': 62,
    'Trial': 73,
    'Adopt': 91,
    'Expand': 66,
    'Renew': 79,
  };

  static const _columnColors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFE11D48),
    Color(0xFF9333EA),
    Color(0xFF4F46E5),
    Color(0xFF0284C7),
    Color(0xFF059669),
    Color(0xFFCA8A04),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF475569),
    Color(0xFFDB2777),
  ];

  @override
  void initState() {
    super.initState();
    _values = Map<String, num>.of(_standardValues);
  }

  @override
  void dispose() {
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Polar Column',
      subtitle:
          'Compare category magnitudes on angular categories and a numeric radial axis',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('polar-column-regenerate'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _regenerateValues,
          icon: const Icon(Icons.casino_outlined, size: 18),
          label: const Text('Regenerate values'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const ValueKey('polar-column-showcase-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresentationSelector(constraints.maxWidth),
              const SizedBox(height: 16),
              _buildInteractionNotice(),
              const SizedBox(height: 16),
              _buildChartCard(),
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
  }

  Widget _buildPresentationSelector(double availableWidth) {
    final compact = availableWidth < 760;
    final cardWidth = compact ? availableWidth : (availableWidth - 16) / 3;
    return Semantics(
      container: true,
      label: 'Choose a Polar Column presentation',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final presentation in _PolarPresentation.values)
            SizedBox(
              width: cardWidth,
              child: _PresentationCard(
                presentation: presentation,
                selected: presentation == _presentation,
                onPressed: () => _applyPresentation(presentation),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionNotice() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selection = _selectedCategory == null
        ? 'Select a column to inspect its exact category and value.'
        : 'Selected: $_selectedCategory. Select it again or press Escape to clear.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ads_click_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Angle finds the category; radius compares the value',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selection Use arrow keys to move between columns and Enter to select.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chartTheme = isDark ? ChartTheme.dark : ChartTheme.light;
    final config = _buildPolarConfig();

    return Card(
      key: const ValueKey('polar-column-chart-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                      Text(
                        _presentation.chartTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _presentation.chartSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _MetricChip(label: '${_values.length} categories'),
                const SizedBox(width: 8),
                _MetricChip(
                  label: _scaleMode == PolarRadialScaleMode.areaCorrect
                      ? 'Area-correct'
                      : 'Linear radius',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const ValueKey('polar-column-live-chart'),
              height: 620,
              child: BravenChartWorkbench(
                chartController: _chartController,
                workbenchController: _workbenchController,
                initialDisplayMode: ChartDisplayMode.chart,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                sourceOptions: const ChartDartSourceOptions(
                  variableName: 'polarColumnChart',
                ),
                splitBreakpoint: 1,
                splitGap: 8,
                minimumChartPaneExtent: 360,
                minimumTablePaneExtent: 420,
                maximumAutoTablePaneExtent: 560,
                autoFitTablePane: true,
                isSplitResizable: true,
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                onTableRowFocused: _focusTablePoints,
                onTableRowFocusCleared: _chartController.clearPointFocus,
                onTableRowHoverChanged: (points) => points == null
                    ? _chartController.clearPointFocus()
                    : _focusTablePoints(points),
                onTableRowActivated: _selectTablePoints,
                chartBuilder: (context, controller) => BravenChartPlus(
                  key: const ValueKey('polar-column-chart'),
                  series: [_buildSeries()],
                  polarChartConfig: config,
                  bravenChartController: controller,
                  theme: chartTheme,
                  showLegend: false,
                  interactionConfig: const InteractionConfig(
                    tooltip: TooltipConfig(enabled: true),
                  ),
                  onPointTap: _handlePointActivation,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PolarChartConfig _buildPolarConfig() => PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: _startAngle,
      sweepAngleDegrees: _sweepAngle,
      clockwise: _clockwise,
      innerRadiusFactor: _innerRadius,
      outerRadiusFactor: _outerRadius,
    ),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: _innerPadding,
      outerPadding: _outerPadding,
      showLabels: _showAngularLabels,
      showGridLines: _showAngularGrid,
    ),
    radialAxis: PolarNumericAxisConfig(
      scaleMode: _scaleMode,
      tickCount: _tickCount,
      showLabels: _showRadialLabels,
      showGridLines: _showRadialGrid,
    ),
  );

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
    if (revision == null || points.isEmpty) return;
    final target = points.first;
    if (_chartController.selectedPointRefs.contains(target)) {
      _chartController.clearPointSelection();
      setState(() => _selectedCategory = null);
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final series = _buildSeries();
      final point = target.pointIndex < series.points.length
          ? series.points[target.pointIndex]
          : null;
      setState(() => _selectedCategory = point?.label);
    }
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final pointIndex = point.x.round();
    final isSelected = _chartController.selectedPointRefs.contains(
      ChartPointRef(seriesId: seriesId, pointIndex: pointIndex),
    );
    setState(() => _selectedCategory = isSelected ? point.label : null);
  }

  PolarColumnChartSeries _buildSeries() {
    final colors = <String, Color>{};
    for (final (index, category) in _values.keys.indexed) {
      colors[category] = _columnColors[index % _columnColors.length];
    }
    final style = PolarColumnStyle(
      cornerRadius: _cornerRadius,
      opacity: _opacity,
      borderColor: const Color(0xFF334155),
      borderWidth: 0.75,
      showDataLabels: _showValues,
    );
    return _presentation == _PolarPresentation.rose
        ? PolarColumnChartSeries.rose(
            id: 'showcase-polar-column',
            name: 'Monthly volume',
            values: _values,
            columnColors: colors,
            unit: 'requests',
            polarStyle: style,
          )
        : PolarColumnChartSeries.fromMap(
            id: 'showcase-polar-column',
            name: 'Category volume',
            values: _values,
            columnColors: colors,
            unit: 'requests',
            polarStyle: style,
          );
  }

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Data',
      icon: Icons.data_array_outlined,
      children: [
        IntSliderOption(
          label: 'Category count',
          value: _categoryCount,
          min: 3,
          max: 16,
          suffix: 'categories',
          onChanged: _setCategoryCount,
        ),
      ],
    ),
    OptionSection(
      title: 'Polar pane',
      icon: Icons.radar_outlined,
      children: [
        SliderOption(
          label: 'Start angle',
          value: _startAngle,
          min: -180,
          max: 180,
          divisions: 36,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _startAngle = value),
        ),
        SliderOption(
          label: 'Sweep angle',
          value: _sweepAngle,
          min: 90,
          max: 360,
          divisions: 27,
          suffix: '°',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _sweepAngle = value),
        ),
        BoolOption(
          label: 'Clockwise order',
          value: _clockwise,
          onChanged: (value) => setState(() => _clockwise = value),
        ),
        SliderOption(
          label: 'Inner radius',
          value: _innerRadius * 100,
          min: 0,
          max: 55,
          divisions: 11,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _innerRadius = value / 100),
        ),
        SliderOption(
          label: 'Outer radius',
          value: _outerRadius * 100,
          min: 60,
          max: 94,
          divisions: 17,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _outerRadius = value / 100),
        ),
      ],
    ),
    OptionSection(
      title: 'Angular categories',
      icon: Icons.rotate_right_outlined,
      children: [
        SliderOption(
          label: 'Column gap',
          value: _innerPadding,
          min: 0,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _innerPadding = value),
        ),
        SliderOption(
          label: 'Outer padding',
          value: _outerPadding,
          min: 0,
          max: 0.35,
          divisions: 14,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _outerPadding = value),
        ),
        BoolOption(
          label: 'Show category labels',
          value: _showAngularLabels,
          onChanged: (value) => setState(() => _showAngularLabels = value),
        ),
        BoolOption(
          label: 'Show angular grid',
          value: _showAngularGrid,
          onChanged: (value) => setState(() => _showAngularGrid = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Radial values',
      icon: Icons.straighten_outlined,
      children: [
        EnumOption<PolarRadialScaleMode>(
          label: 'Scale mode',
          value: _scaleMode,
          values: PolarRadialScaleMode.values,
          labelBuilder: (value) => switch (value) {
            PolarRadialScaleMode.linear => 'Linear radius',
            PolarRadialScaleMode.areaCorrect => 'Area-correct',
          },
          onChanged: (value) => setState(() => _scaleMode = value),
        ),
        IntSliderOption(
          label: 'Tick count',
          value: _tickCount,
          min: 2,
          max: 8,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
        BoolOption(
          label: 'Show radial labels',
          value: _showRadialLabels,
          onChanged: (value) => setState(() => _showRadialLabels = value),
        ),
        BoolOption(
          label: 'Show radial grid',
          value: _showRadialGrid,
          onChanged: (value) => setState(() => _showRadialGrid = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Columns',
      icon: Icons.view_column_outlined,
      children: [
        SliderOption(
          label: 'Corner radius',
          value: _cornerRadius,
          min: 0,
          max: 18,
          divisions: 18,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        SliderOption(
          label: 'Opacity',
          value: _opacity * 100,
          min: 35,
          max: 100,
          divisions: 13,
          suffix: '%',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _opacity = value / 100),
        ),
        BoolOption(
          label: 'Show values inside columns',
          value: _showValues,
          onChanged: (value) => setState(() => _showValues = value),
        ),
      ],
    ),
  ];

  Widget _buildFeatureGuide() {
    final items = const [
      (
        Icons.rotate_right_outlined,
        'Category owns angle',
        'Every category receives a stable angular band. Value never changes its width.',
      ),
      (
        Icons.straighten_outlined,
        'Value owns radius',
        'A numeric radial scale makes magnitudes comparable instead of converting them into shares.',
      ),
      (
        Icons.nightlight_round,
        'Rose is area-correct',
        'The Nightingale preset maps values to annular-sector area by default.',
      ),
    ];
    return _Section(
      eyebrow: 'FEATURE GUIDE',
      title: 'An axis-based radial chart—not a Pie chart',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 720 ? 1 : 3;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.8 : 1.8,
            children: [
              for (final item in items)
                _FeatureCard(icon: item.$1, title: item.$2, body: item.$3),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCodeRecipe() => const _Section(
    eyebrow: 'HOW TO USE IT',
    title: 'Declare categories once, then configure the polar pane',
    child: _CodeBlock(
      code: '''final series = PolarColumnChartSeries.rose(
  id: 'monthly-volume',
  values: const {'Jan': 42, 'Feb': 58, 'Mar': 76},
  unit: 'requests',
);

BravenChartPlus(
  series: [series],
  polarChartConfig: const PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: -90),
    angularAxis: PolarCategoryAxisConfig(innerPadding: 0.12),
    radialAxis: PolarNumericAxisConfig(tickCount: 5),
  ),
);''',
    ),
  );

  void _applyPresentation(_PolarPresentation presentation) {
    setState(() {
      _presentation = presentation;
      _selectedCategory = null;
      switch (presentation) {
        case _PolarPresentation.standard:
          _values = Map<String, num>.of(_standardValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0;
          _outerRadius = 0.84;
          _innerPadding = 0.12;
          _outerPadding = 0.04;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 4;
        case _PolarPresentation.rose:
          _values = Map<String, num>.of(_roseValues);
          _categoryCount = _values.length;
          _startAngle = -90;
          _sweepAngle = 360;
          _clockwise = true;
          _innerRadius = 0.08;
          _outerRadius = 0.86;
          _innerPadding = 0.08;
          _outerPadding = 0;
          _scaleMode = PolarRadialScaleMode.areaCorrect;
          _cornerRadius = 6;
        case _PolarPresentation.partial:
          _values = Map<String, num>.of(_partialValues);
          _categoryCount = _values.length;
          _startAngle = 150;
          _sweepAngle = 240;
          _clockwise = true;
          _innerRadius = 0.28;
          _outerRadius = 0.9;
          _innerPadding = 0.14;
          _outerPadding = 0.08;
          _scaleMode = PolarRadialScaleMode.linear;
          _cornerRadius = 8;
      }
    });
  }

  void _setCategoryCount(int count) {
    setState(() {
      _categoryCount = count;
      _selectedCategory = null;
      _values = _randomValues(count);
    });
  }

  void _regenerateValues() {
    setState(() {
      _selectedCategory = null;
      _values = _randomValues(_categoryCount);
    });
  }

  Map<String, num> _randomValues(int count) => {
    for (var index = 0; index < count; index++)
      'Category ${index + 1}': 24 + _random.nextInt(77),
  };
}

enum _PolarPresentation {
  standard(
    'Standard columns',
    'Linear radius for direct category comparison',
    Icons.view_column_outlined,
    'Channel volume',
    'Equal angular bands compare one numeric measure across categories',
  ),
  rose(
    'Nightingale rose',
    'Area-correct sectors for cyclical profiles',
    Icons.nightlight_round,
    'Monthly request profile',
    'Equal angles with area-correct radial scaling across a complete cycle',
  ),
  partial(
    'Partial sweep',
    'A controlled angular span with an open center',
    Icons.speed_outlined,
    'Lifecycle conversion',
    'A 240° pane demonstrates start angle, sweep, and annular baselines',
  );

  const _PolarPresentation(
    this.label,
    this.description,
    this.icon,
    this.chartTitle,
    this.chartSubtitle,
  );

  final String label;
  final String description;
  final IconData icon;
  final String chartTitle;
  final String chartSubtitle;
}

class _PresentationCard extends StatelessWidget {
  const _PresentationCard({
    required this.presentation,
    required this.selected,
    required this.onPressed,
  });

  final _PolarPresentation presentation;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.secondaryContainer
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('polar-presentation-${presentation.name}'),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  presentation.icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18, color: scheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
