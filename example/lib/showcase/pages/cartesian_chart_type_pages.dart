// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _CartesianFamily { line, area, scatter }

class LineChartsPage extends StatelessWidget {
  const LineChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.line);
}

class AreaChartsPage extends StatelessWidget {
  const AreaChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.area);
}

class ScatterChartsPage extends StatelessWidget {
  const ScatterChartsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CartesianChartTypePage(family: _CartesianFamily.scatter);
}

class _CartesianChartTypePage extends StatefulWidget {
  const _CartesianChartTypePage({required this.family});

  final _CartesianFamily family;

  @override
  State<_CartesianChartTypePage> createState() =>
      _CartesianChartTypePageState();
}

class _CartesianChartTypePageState extends State<_CartesianChartTypePage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showDataMarkers: true),
  );

  int _presetIndex = 0;
  LineInterpolation _interpolation = LineInterpolation.monotone;
  double _strokeWidth = 2.5;
  double _lineGlow = 0;
  double _fillOpacity = 0.24;
  double _markerRadius = 5;
  bool _showSecondSeries = true;
  bool _showPointLabels = false;
  bool _showBaselineFill = true;
  bool _useAreaGradient = true;
  bool _animatePaths = true;
  double _motionDurationMs = 650;
  late double _motionSeriesDelayMs;
  int _motionValueRevision = 0;
  late List<ChartDataPoint> _motionPrimaryPoints;
  late List<ChartDataPoint> _motionSecondaryPoints;
  ChartDisplayMode _initialDisplayMode = ChartDisplayMode.chart;

  @override
  void initState() {
    super.initState();
    _motionSeriesDelayMs = _defaultMotionSeriesDelayMs;
    _resetMotionData();
    final requestedPreset = Uri.base.queryParameters['preset']?.toLowerCase();
    if (requestedPreset != null) {
      final index = _presets.indexWhere(
        (preset) => preset.label.toLowerCase() == requestedPreset,
      );
      if (index >= 0) _presetIndex = index;
    }
    final requestedView = Uri.base.queryParameters['view'];
    for (final mode in ChartDisplayMode.values) {
      if (mode.name == requestedView) {
        _initialDisplayMode = mode;
        break;
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _workbenchController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: _pageTitle,
      subtitle: _pageSubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresetPicker(compact: compact),
              SizedBox(height: compact ? 8 : 16),
              Expanded(child: _buildChartCard()),
              if (!compact) ...[
                const SizedBox(height: 16),
                _FeatureCoverage(family: widget.family),
              ],
            ],
          );
        },
      ),
    );
  }

  String get _pageTitle => switch (widget.family) {
    _CartesianFamily.line => 'Line Charts',
    _CartesianFamily.area => 'Area Charts',
    _CartesianFamily.scatter => 'Scatter Charts',
  };

  String get _presetPickerTitle => switch (widget.family) {
    _CartesianFamily.line => 'Choose a line chart example',
    _CartesianFamily.area => 'Choose an area chart example',
    _CartesianFamily.scatter => 'Choose a scatter chart example',
  };

  String get _pageSubtitle => switch (widget.family) {
    _CartesianFamily.line =>
      'The analytical workhorse: trends, interpolation, axes, tracking, and annotations',
    _CartesianFamily.area =>
      'Show magnitude, layering, and positive or negative deviation from a baseline',
    _CartesianFamily.scatter =>
      'Compare observation sets, reveal relationships, and inspect outliers',
  };

  List<_ChartTypePreset> get _presets => switch (widget.family) {
    _CartesianFamily.line => const [
      _ChartTypePreset(
        label: 'Workhorse',
        icon: Icons.monitor_heart_outlined,
        description: 'Two tracked signals with stages, a threshold, and peak.',
      ),
      _ChartTypePreset(
        label: 'Interpolation',
        icon: Icons.gesture,
        description: 'Linear, bezier, monotone, and stepped geometry together.',
      ),
      _ChartTypePreset(
        label: 'Multi-axis',
        icon: Icons.align_vertical_bottom_outlined,
        description: 'Independent units remain readable in one plot.',
      ),
      _ChartTypePreset(
        label: 'Motion',
        icon: Icons.animation,
        description: 'Reveal paths, then interpolate real value updates.',
      ),
      _ChartTypePreset(
        label: 'Comparison',
        icon: Icons.multiline_chart,
        description: 'Current, previous, and target trends share one scale.',
      ),
      _ChartTypePreset(
        label: 'Envelope',
        icon: Icons.area_chart_outlined,
        description: 'A gradient capacity envelope supports the observed line.',
      ),
      _ChartTypePreset(
        label: 'Spotlight',
        icon: Icons.blur_on,
        description: 'A luminous focus line stands over soft gradient context.',
      ),
    ],
    _CartesianFamily.area => const [
      _ChartTypePreset(
        label: 'Layered',
        icon: Icons.layers_outlined,
        description: 'Related volumes share a plot with restrained opacity.',
      ),
      _ChartTypePreset(
        label: 'Baseline',
        icon: Icons.compare_arrows,
        description: 'Positive and negative deviation use distinct fills.',
      ),
      _ChartTypePreset(
        label: 'Forecast',
        icon: Icons.cloud_outlined,
        description: 'A contextual range sits behind the observed line.',
      ),
      _ChartTypePreset(
        label: 'Motion',
        icon: Icons.animation,
        description: 'Fill and stroke reveal and update as one geometry.',
      ),
      _ChartTypePreset(
        label: 'Gradient',
        icon: Icons.gradient,
        description: 'A plot-bound gradient adds depth without obscuring data.',
      ),
      _ChartTypePreset(
        label: 'Composition',
        icon: Icons.stacked_line_chart,
        description: 'Two area layers combine with a crisp reference line.',
      ),
      _ChartTypePreset(
        label: 'Pulse',
        icon: Icons.auto_graph,
        description:
            'Gradient magnitude meets a target window and marked peak.',
      ),
    ],
    _CartesianFamily.scatter => const [
      _ChartTypePreset(
        label: 'Cohorts',
        icon: Icons.groups_outlined,
        description: 'Two populations use distinct size and colour.',
      ),
      _ChartTypePreset(
        label: 'Correlation',
        icon: Icons.trending_up,
        description: 'A trend annotation summarizes the relationship.',
      ),
      _ChartTypePreset(
        label: 'Outliers',
        icon: Icons.crisis_alert_outlined,
        description: 'Point-level styling makes unusual observations explicit.',
      ),
    ],
  };

  Widget _buildPresetPicker({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _presetPickerTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                key: ValueKey('${widget.family.name}-preset-picker'),
                showSelectedIcon: false,
                segments: [
                  for (var index = 0; index < _presets.length; index++)
                    ButtonSegment(
                      value: index,
                      icon: Icon(_presets[index].icon, size: 18),
                      label: Text(_presets[index].label),
                    ),
                ],
                selected: {_presetIndex},
                onSelectionChanged: (selection) {
                  setState(() {
                    _presetIndex = selection.single;
                    _resetMotionData();
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _presets[_presetIndex].description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final options = _optionsController.options;
        return ChartCard(
          title: _presets[_presetIndex].label,
          subtitle: _chartSummary,
          padding: const EdgeInsets.all(8),
          child: BravenChartWorkbench(
            key: ValueKey('${widget.family.name}-workbench'),
            chartController: _chartController,
            workbenchController: _workbenchController,
            initialDisplayMode: _initialDisplayMode,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.data,
              ChartDisplayMode.split,
              ChartDisplayMode.source,
            },
            sourceOptions: ChartDartSourceOptions(
              variableName: '${widget.family.name}Chart',
            ),
            tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
            splitBreakpoint: 760,
            autoFitTablePane: true,
            minimumChartPaneExtent: 360,
            minimumTablePaneExtent: 360,
            maximumAutoTablePaneExtent: 520,
            chartBuilder: (context, controller) =>
                _buildChart(options, controller),
          ),
        );
      },
    );
  }

  Widget _buildChart(ChartOptions options, BravenChartController controller) {
    final baseTheme = options.theme ?? ChartTheme.light;
    final effectiveTheme = _isLineSpotlight ? ChartTheme.dark : baseTheme;
    return BravenChartPlus(
      key: ValueKey('${widget.family.name}-chart'),
      bravenChartController: controller,
      series: _buildSeries(),
      annotations: _buildAnnotations(),
      theme: effectiveTheme.copyWith(
        animationTheme: effectiveTheme.animationTheme.copyWith(
          dataUpdateDuration: Duration(milliseconds: _motionDurationMs.round()),
          dataUpdateCurve: Curves.easeInOutCubic,
        ),
      ),
      showLegend: (_isLineSpotlight || _isAreaPulse)
          ? false
          : options.showLegend,
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      grid: GridConfig(
        horizontal: options.showGrid,
        vertical: options.showGrid,
      ),
      xAxisConfig: XAxisConfig(
        label: _xAxisLabel,
        showAxisLine: options.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: _yAxisLabel,
        showAxisLine: options.showAxisLines,
      ),
      normalizationMode:
          _presetIndex == 2 && widget.family == _CartesianFamily.line
          ? NormalizationMode.perSeries
          : NormalizationMode.none,
      interactionConfig: InteractionConfig(
        enableZoom: options.enableZoom,
        enablePan: options.enablePan,
        showXScrollbar: options.showXScrollbar,
        showYScrollbar: options.showYScrollbar,
        crosshair: const CrosshairConfig(
          enabled: true,
          mode: CrosshairMode.both,
          snapToDataPoint: true,
          displayMode: CrosshairDisplayMode.tracking,
        ),
        tooltip: const TooltipConfig(enabled: true),
      ),
    );
  }

  String get _chartSummary => switch (widget.family) {
    _CartesianFamily.line =>
      '${_buildSeries().length} series · ${_interpolation.name} · tracking enabled',
    _CartesianFamily.area =>
      '${_buildSeries().length} series · ${(_fillOpacity * 100).round()}% fill${_presetIndex >= 4 && _useAreaGradient ? ' · gradient' : ''} · ${_interpolation.name}',
    _CartesianFamily.scatter =>
      '${_buildSeries().length} cohorts · ${_markerRadius.toStringAsFixed(0)}px markers · tracking enabled',
  };

  String get _xAxisLabel => switch (widget.family) {
    _CartesianFamily.line => 'Elapsed interval',
    _CartesianFamily.area => 'Period',
    _CartesianFamily.scatter => 'Input',
  };

  String get _yAxisLabel => switch (widget.family) {
    _CartesianFamily.line => 'Value',
    _CartesianFamily.area => 'Magnitude',
    _CartesianFamily.scatter => 'Outcome',
  };

  List<Widget> _buildOptions() {
    final typeOptions = <Widget>[
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        EnumOption<LineInterpolation>(
          label: 'Interpolation',
          value: _interpolation,
          values: LineInterpolation.values,
          onChanged: (value) => setState(() => _interpolation = value),
        ),
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        SliderOption(
          label: 'Stroke width',
          value: _strokeWidth,
          min: 1,
          max: 5,
          divisions: 8,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _strokeWidth = value),
        ),
      if (widget.family != _CartesianFamily.scatter &&
          !_isLineSpotlight &&
          !_isAreaPulse)
        SliderOption(
          label: 'Line glow',
          value: _lineGlow,
          min: 0,
          max: 10,
          divisions: 10,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _lineGlow = value),
        ),
      if (widget.family == _CartesianFamily.area)
        SliderOption(
          label: 'Fill opacity',
          value: _fillOpacity,
          min: 0.05,
          max: 0.8,
          divisions: 15,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _fillOpacity = value),
        ),
      if (widget.family == _CartesianFamily.scatter)
        SliderOption(
          label: 'Marker radius',
          value: _markerRadius,
          min: 2,
          max: 10,
          divisions: 8,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _markerRadius = value),
        ),
      BoolOption(
        label: widget.family == _CartesianFamily.scatter
            ? 'Show second cohort'
            : 'Show second series',
        value: _showSecondSeries,
        onChanged: (value) => setState(() => _showSecondSeries = value),
      ),
      if (widget.family != _CartesianFamily.scatter)
        BoolOption(
          label: 'Show point labels',
          value: _showPointLabels,
          onChanged: (value) => setState(() => _showPointLabels = value),
        ),
      if (widget.family == _CartesianFamily.area && _presetIndex == 1)
        BoolOption(
          label: 'Use baseline fills',
          value: _showBaselineFill,
          onChanged: (value) => setState(() => _showBaselineFill = value),
          subtitle: 'Apply positive and negative fills in the baseline preset',
        ),
      if (widget.family == _CartesianFamily.area && _presetIndex >= 4)
        BoolOption(
          key: const ValueKey('area-gradient-fill'),
          label: 'Gradient fill',
          value: _useAreaGradient,
          onChanged: (value) => setState(() => _useAreaGradient = value),
          subtitle: 'Blend configured colors across the plot',
        ),
    ];

    return [
      OptionSection(
        title: '${_pageTitle.replaceAll(' Charts', '')} options',
        icon: switch (widget.family) {
          _CartesianFamily.line => Icons.show_chart,
          _CartesianFamily.area => Icons.area_chart_outlined,
          _CartesianFamily.scatter => Icons.scatter_plot_outlined,
        },
        children: typeOptions,
      ),
      if (widget.family != _CartesianFamily.scatter && _presetIndex == 3)
        OptionSection(
          title: 'Motion',
          icon: Icons.animation,
          children: [
            SliderOption(
              label: 'Duration',
              value: _motionDurationMs,
              min: 150,
              max: 1200,
              divisions: 21,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _motionDurationMs = value),
            ),
            SliderOption(
              key: ValueKey('${widget.family.name}-series-delay'),
              label: 'Series delay',
              value: _motionSeriesDelayMs,
              min: 0,
              max: 240,
              divisions: 12,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _motionSeriesDelayMs = value),
            ),
            BoolOption(
              label: 'Animate paths',
              value: _animatePaths,
              subtitle: 'Reduced-motion settings always take priority',
              onChanged: (value) => setState(() => _animatePaths = value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-replay-entrance'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _chartController.replaySeriesEntrance,
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay entrance'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-update-values'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _updateMotionValues,
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Update values'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-backfill-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _toggleMotionBackfill,
                  icon: Icon(
                    _hasMotionBackfill
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    _hasMotionBackfill ? 'Remove backfill' : 'Add backfill',
                  ),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-add-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _addMotionPoint,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add point'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-remove-point'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _motionPrimaryPoints.length > 2
                      ? _removeMotionPoint
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                  label: const Text('Remove point'),
                ),
                OutlinedButton.icon(
                  key: ValueKey('${widget.family.name}-roll-window'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _motionPrimaryPoints.length > 1
                      ? _rollMotionWindow
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Roll window'),
                ),
              ],
            ),
            Text(
              _animatePaths
                  ? '${_motionPrimaryPoints.length} points · ${_motionSeriesDelayMs.round()} ms explicit series delay'
                  : 'Path animation is off · updates apply immediately',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      StandardChartOptions(
        controller: _optionsController,
        showThemeOption: !_isLineSpotlight,
        showLegendOption: !_isLineSpotlight && !_isAreaPulse,
        showLineStyleOption: false,
      ),
    ];
  }

  List<ChartSeries> _buildSeries() => switch (widget.family) {
    _CartesianFamily.line => _buildLineSeries(),
    _CartesianFamily.area => _buildAreaSeries(),
    _CartesianFamily.scatter => _buildScatterSeries(),
  };

  List<ChartSeries> _buildLineSeries() {
    if (_presetIndex == 3) {
      return [
        _line(
          id: 'motion-observed',
          name: 'Observed',
          unit: 'W',
          points: _motionPrimaryPoints,
          color: const Color(0xFF2563EB),
          motionSequence: 0,
        ),
        if (_showSecondSeries)
          _line(
            id: 'motion-plan',
            name: 'Plan',
            unit: 'W',
            points: _motionSecondaryPoints,
            color: const Color(0xFFF97316),
            motionSequence: 1,
          ),
        if (_showSecondSeries)
          _line(
            id: 'motion-capacity',
            name: 'Capacity',
            unit: 'W',
            points: _motionCapacityPoints,
            color: const Color(0xFF0F9F8F),
            motionSequence: 2,
          ),
      ];
    }
    if (_presetIndex == 1) {
      final modes = LineInterpolation.values;
      const colors = [
        Color(0xFF2563EB),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
      ];
      return [
        for (var index = 0; index < modes.length; index++)
          LineChartSeries(
            id: 'interpolation-${modes[index].name}',
            name: modes[index].name,
            points: _offsetPoints(_primaryPoints, index * 7.0),
            color: colors[index],
            interpolation: modes[index],
            strokeWidth: _strokeWidth,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 2.5,
            lineGlow: _lineGlow,
          ),
      ];
    }
    if (_presetIndex == 2) {
      return [
        _line(
          id: 'power',
          name: 'Power',
          unit: 'W',
          points: _powerPoints,
          color: const Color(0xFFF97316),
          axis: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            color: const Color(0xFFF97316),
          ),
        ),
        _line(
          id: 'heart-rate',
          name: 'Heart rate',
          unit: 'bpm',
          points: _heartRatePoints,
          color: const Color(0xFF3B82F6),
          axis: YAxisConfig(
            position: YAxisPosition.right,
            label: 'Heart rate',
            unit: 'bpm',
            color: const Color(0xFF3B82F6),
          ),
        ),
        if (_showSecondSeries)
          _line(
            id: 'lactate',
            name: 'Lactate',
            unit: 'mmol/L',
            points: _lactatePoints,
            color: const Color(0xFFE11D48),
            axis: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Lactate',
              unit: 'mmol/L',
              color: const Color(0xFFE11D48),
            ),
          ),
      ];
    }
    if (_presetIndex == 4) {
      return [
        _line(
          id: 'comparison-current',
          name: 'Current',
          unit: 'W',
          points: _primaryPoints,
          color: const Color(0xFF2563EB),
        ),
        if (_showSecondSeries)
          _line(
            id: 'comparison-previous',
            name: 'Previous',
            unit: 'W',
            points: _offsetPoints(_primaryPoints, -6),
            color: const Color(0xFF8B5CF6),
          ),
        if (_showSecondSeries)
          _line(
            id: 'comparison-target',
            name: 'Target',
            unit: 'W',
            points: _secondaryPoints,
            color: const Color(0xFFF97316),
          ),
      ];
    }
    if (_presetIndex == 5) {
      return [
        _area(
          id: 'capacity-envelope',
          name: 'Capacity envelope',
          points: _offsetPoints(_secondaryPoints, 10),
          color: const Color(0xFF818CF8),
          fillOpacity: 0.32,
          fillGradient: const AreaGradient(
            colors: [Color(0xFF6366F1), Color(0x196366F1)],
          ),
        ),
        _line(
          id: 'envelope-observed',
          name: 'Observed',
          unit: 'W',
          points: _primaryPoints,
          color: const Color(0xFF0F9F8F),
        ),
      ];
    }
    if (_presetIndex == 6) {
      return [
        if (_showSecondSeries)
          const AreaChartSeries(
            id: 'spotlight-context',
            name: 'Expected range',
            points: _spotlightContextPoints,
            color: Color(0xFF22D3EE),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.2,
            fillOpacity: 0.16,
            fillGradient: AreaGradient(
              colors: [Color(0xFF22D3EE), Color(0x3322D3EE)],
            ),
          ),
        LineChartSeries(
          id: 'spotlight-signal',
          name: 'Live signal',
          points: _spotlightSignalPoints,
          color: const Color(0xFFA78BFA),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 3,
          lineGlow: 8,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: 3,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
          inlineLabel: const SeriesInlineLabelConfig(
            text: 'Live signal',
            position: SeriesLabelPosition.right,
            offsetY: -10,
            color: Color(0xFFC4B5FD),
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }
    return [
      _line(
        id: 'observed',
        name: 'Observed',
        unit: 'W',
        points: _primaryPoints,
        color: const Color(0xFF2563EB),
      ),
      if (_showSecondSeries)
        _line(
          id: 'target',
          name: 'Target',
          unit: 'W',
          points: _secondaryPoints,
          color: const Color(0xFFF97316),
        ),
    ];
  }

  LineChartSeries _line({
    required String id,
    required String name,
    required String unit,
    required List<ChartDataPoint> points,
    required Color color,
    YAxisConfig? axis,
    int motionSequence = 0,
  }) {
    return LineChartSeries(
      id: id,
      name: name,
      unit: unit,
      points: points,
      color: color,
      interpolation: _interpolation,
      strokeWidth: _strokeWidth,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointMarkerRadius: 3,
      lineGlow: _lineGlow,
      dataPointLabels: DataPointLabelConfig(
        show: _showPointLabels,
        showUnit: true,
      ),
      yAxisConfig: axis,
      pathAnimation: _pathAnimationFor(motionSequence),
    );
  }

  List<ChartSeries> _buildAreaSeries() {
    if (_presetIndex == 3) {
      return [
        _area(
          id: 'motion-volume',
          name: 'Volume',
          points: _motionPrimaryPoints,
          color: const Color(0xFF4F46E5),
          fillOpacity: _fillOpacity,
          motionSequence: 0,
        ),
        if (_showSecondSeries)
          _area(
            id: 'motion-plan',
            name: 'Plan',
            points: _motionSecondaryPoints,
            color: const Color(0xFF0891B2),
            fillOpacity: (_fillOpacity * 0.55).clamp(0.06, 0.22),
            motionSequence: 1,
          ),
      ];
    }
    if (_presetIndex == 1) {
      return [
        AreaChartSeries(
          id: 'baseline-delta',
          name: 'Delta from target',
          unit: '%',
          points: _baselinePoints,
          color: const Color(0xFF8B5CF6),
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          fillOpacity: _fillOpacity,
          lineGlow: _lineGlow,
          baselineValue: _showBaselineFill ? 0 : null,
          aboveBaselineFillColor: _showBaselineFill
              ? const Color(0x4434D399)
              : null,
          belowBaselineFillColor: _showBaselineFill
              ? const Color(0x44FB7185)
              : null,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
        ),
      ];
    }
    if (_presetIndex == 2) {
      return [
        AreaChartSeries(
          id: 'forecast-range',
          name: 'Forecast range',
          points: _secondaryPoints,
          color: const Color(0xFF60A5FA),
          interpolation: _interpolation,
          strokeWidth: 1,
          fillOpacity: _fillOpacity,
        ),
        _line(
          id: 'forecast-observed',
          name: 'Observed',
          unit: 'k',
          points: _primaryPoints,
          color: const Color(0xFF0F9F8F),
        ),
      ];
    }
    if (_presetIndex == 4) {
      return [
        _area(
          id: 'gradient-throughput',
          name: 'Throughput',
          points: _primaryPoints,
          color: const Color(0xFF4F46E5),
          fillOpacity: _fillOpacity,
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF4F46E5), Color(0x1A06B6D4)],
                  stops: [0, 1],
                )
              : null,
        ),
      ];
    }
    if (_presetIndex == 5) {
      return [
        _area(
          id: 'composition-total',
          name: 'Total demand',
          points: _offsetPoints(_secondaryPoints, 18),
          color: const Color(0xFF6366F1),
          fillOpacity: (_fillOpacity * 0.72).clamp(0.08, 0.48),
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF6366F1), Color(0x146366F1)],
                )
              : null,
        ),
        if (_showSecondSeries)
          _area(
            id: 'composition-active',
            name: 'Active demand',
            points: _primaryPoints,
            color: const Color(0xFF06B6D4),
            fillOpacity: _fillOpacity,
            fillGradient: _useAreaGradient
                ? const AreaGradient(
                    colors: [Color(0xFF06B6D4), Color(0x1406B6D4)],
                  )
                : null,
          ),
        _line(
          id: 'composition-plan',
          name: 'Plan',
          unit: 'k',
          points: _secondaryPoints,
          color: const Color(0xFFF97316),
        ),
      ];
    }
    if (_presetIndex == 6) {
      return [
        AreaChartSeries(
          id: 'pulse-live-load',
          name: 'Live load',
          unit: 'k',
          points: _pulseLivePoints,
          color: const Color(0xFF6366F1),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
          fillOpacity: _fillOpacity,
          fillGradient: _useAreaGradient
              ? const AreaGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                  stops: [0, 1],
                )
              : null,
          lineGlow: 3,
          showDataPointMarkers: _optionsController.showDataMarkers,
          dataPointMarkerRadius: 3,
          dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
          inlineLabel: const SeriesInlineLabelConfig(
            text: 'Live load',
            position: SeriesLabelPosition.right,
            offsetY: -10,
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            background: SeriesLabelBackground(
              color: Color(0xEFFFFFFF),
              borderColor: Color(0x556366F1),
            ),
          ),
        ),
        if (_showSecondSeries)
          const LineChartSeries(
            id: 'pulse-target',
            name: 'Target',
            unit: 'k',
            points: _pulseTargetPoints,
            color: Color(0xFFF97316),
            interpolation: LineInterpolation.stepped,
            strokeWidth: 2,
            inlineLabel: SeriesInlineLabelConfig(
              text: 'Target',
              position: SeriesLabelPosition.center,
              offsetY: 10,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w700,
            ),
          ),
      ];
    }
    return [
      _area(
        id: 'sessions',
        name: 'Sessions',
        points: _offsetPoints(_secondaryPoints, 18),
        color: const Color(0xFF6366F1),
      ),
      if (_showSecondSeries)
        _area(
          id: 'active-users',
          name: 'Active users',
          points: _primaryPoints,
          color: const Color(0xFF06B6D4),
        ),
    ];
  }

  AreaChartSeries _area({
    required String id,
    required String name,
    required List<ChartDataPoint> points,
    required Color color,
    double? fillOpacity,
    AreaGradient? fillGradient,
    int motionSequence = 0,
  }) {
    return AreaChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      interpolation: _interpolation,
      strokeWidth: _strokeWidth,
      fillOpacity: fillOpacity ?? _fillOpacity,
      fillGradient: fillGradient,
      lineGlow: _lineGlow,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
      pathAnimation: _pathAnimationFor(motionSequence),
    );
  }

  PathAnimationStyle _pathAnimationFor(int motionSequence) =>
      _animatePaths && _presetIndex == 3
      ? PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
          entranceTiming: PathAnimationTiming(
            delay: Duration(
              milliseconds: _motionSeriesDelayMs.round() * motionSequence,
            ),
          ),
          dataUpdateTiming: PathAnimationTiming(
            delay: Duration(
              milliseconds: _motionSeriesDelayMs.round() * motionSequence,
            ),
          ),
        )
      : const PathAnimationStyle();

  double get _defaultMotionSeriesDelayMs =>
      widget.family == _CartesianFamily.area ? 120 : 80;

  List<ChartDataPoint> get _motionCapacityPoints => [
    for (var index = 0; index < _motionPrimaryPoints.length; index++)
      _motionPrimaryPoints[index].copyWith(
        y:
            ((_motionPrimaryPoints[index].y + _motionSecondaryPoints[index].y) /
                2) +
            12,
      ),
  ];

  List<ChartSeries> _buildScatterSeries() {
    final primary = ScatterChartSeries(
      id: 'cohort-a',
      name: _presetIndex == 2 ? 'Expected' : 'Cohort A',
      points: _scatterPrimary,
      color: const Color(0xFF8B5CF6),
      markerRadius: _markerRadius,
    );
    final secondary = ScatterChartSeries(
      id: 'cohort-b',
      name: _presetIndex == 2 ? 'Review' : 'Cohort B',
      points: _presetIndex == 2 ? _scatterOutliers : _scatterSecondary,
      color: _presetIndex == 2
          ? const Color(0xFFEF4444)
          : const Color(0xFFF97316),
      markerRadius: _presetIndex == 2 ? _markerRadius + 2 : _markerRadius - 1,
    );
    return [primary, if (_showSecondSeries) secondary];
  }

  List<ChartAnnotation> _buildAnnotations() {
    if (widget.family == _CartesianFamily.line && _presetIndex == 0) {
      return [
        RangeAnnotation(
          id: 'work-stage',
          startX: 2.5,
          endX: 5.5,
          label: 'Work block',
          fillColor: const Color(0x123B82F6),
          borderColor: const Color(0x443B82F6),
          allowDragging: false,
          allowEditing: false,
        ),
        ThresholdAnnotation(
          id: 'target-threshold',
          axis: AnnotationAxis.y,
          value: 50,
          label: 'Target · 50 W',
          lineColor: const Color(0xFFF59E0B),
          dashPattern: const [6, 4],
          allowDragging: false,
          allowEditing: false,
        ),
        PointAnnotation(
          id: 'peak',
          seriesId: 'observed',
          dataPointIndex: 6,
          label: 'Peak',
          markerShape: MarkerShape.star,
          markerColor: const Color(0xFF2563EB),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isLineSpotlight) {
      return [
        ThresholdAnnotation(
          id: 'spotlight-threshold',
          axis: AnnotationAxis.y,
          value: 60,
          label: 'Upper threshold',
          lineColor: const Color(0xFFFBBF24),
          lineWidth: 1.5,
          dashPattern: const [5, 4],
          elevation: 5,
          style: const AnnotationStyle(
            textStyle: TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Color(0xCC111827),
            borderColor: Color(0x66FBBF24),
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (_isAreaPulse) {
      return [
        RangeAnnotation(
          id: 'pulse-target-window',
          startX: 2.5,
          endX: 5.5,
          startY: 42,
          endY: 58,
          label: 'Target window',
          fillColor: const Color(0x1422D3EE),
          borderColor: const Color(0x5522D3EE),
          allowDragging: false,
          allowEditing: false,
        ),
        PointAnnotation(
          id: 'pulse-peak',
          seriesId: 'pulse-live-load',
          dataPointIndex: 6,
          label: 'Peak',
          markerShape: MarkerShape.star,
          markerColor: const Color(0xFF6366F1),
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    if (widget.family == _CartesianFamily.scatter && _presetIndex == 1) {
      return [
        TrendAnnotation(
          id: 'scatter-trend',
          seriesId: 'cohort-a',
          trendType: TrendType.linear,
          label: 'Linear fit',
          lineColor: const Color(0xFF2563EB),
          dashPattern: const [6, 4],
          allowDragging: false,
          allowEditing: false,
        ),
      ];
    }
    return const [];
  }

  bool get _isLineSpotlight =>
      widget.family == _CartesianFamily.line && _presetIndex == 6;

  bool get _isAreaPulse =>
      widget.family == _CartesianFamily.area && _presetIndex == 6;

  void _reset() {
    setState(() {
      _presetIndex = 0;
      _interpolation = LineInterpolation.monotone;
      _strokeWidth = 2.5;
      _lineGlow = 0;
      _fillOpacity = 0.24;
      _markerRadius = 5;
      _showSecondSeries = true;
      _showPointLabels = false;
      _showBaselineFill = true;
      _useAreaGradient = true;
      _animatePaths = true;
      _motionDurationMs = 650;
      _motionSeriesDelayMs = _defaultMotionSeriesDelayMs;
      _resetMotionData();
    });
    _optionsController.update(const ChartOptions(showDataMarkers: true));
  }

  void _resetMotionData() {
    _motionPrimaryPoints = List<ChartDataPoint>.of(_primaryPoints);
    _motionSecondaryPoints = List<ChartDataPoint>.of(_secondaryPoints);
    _motionValueRevision = 0;
  }

  void _updateMotionValues() {
    const primaryDelta = <double>[6, 6, 6, 8, 7, 8, -5, 10];
    const secondaryDelta = <double>[-3, 4, 6, 4, 5, 5, 6, 5];
    final direction = _motionValueRevision.isEven ? 1.0 : -1.0;
    setState(() {
      _motionPrimaryPoints = _motionPrimaryPoints
          .asMap()
          .entries
          .map(
            (entry) => entry.value.copyWith(
              y:
                  entry.value.y +
                  (primaryDelta[entry.key % primaryDelta.length] * direction),
            ),
          )
          .toList(growable: false);
      _motionSecondaryPoints = _motionSecondaryPoints
          .asMap()
          .entries
          .map(
            (entry) => entry.value.copyWith(
              y:
                  entry.value.y +
                  (secondaryDelta[entry.key % secondaryDelta.length] *
                      direction),
            ),
          )
          .toList(growable: false);
      _motionValueRevision++;
    });
  }

  bool get _hasMotionBackfill =>
      _motionPrimaryPoints.any((point) => point.label == 'Backfill');

  void _toggleMotionBackfill() {
    setState(() {
      if (_hasMotionBackfill) {
        _motionPrimaryPoints = _motionPrimaryPoints
            .where((point) => point.label != 'Backfill')
            .toList(growable: false);
        _motionSecondaryPoints = _motionSecondaryPoints
            .where((point) => point.label != 'Backfill')
            .toList(growable: false);
        return;
      }

      final insertionIndex = _motionPrimaryPoints.length ~/ 2;
      final primaryBefore = _motionPrimaryPoints[insertionIndex - 1];
      final primaryAfter = _motionPrimaryPoints[insertionIndex];
      final secondaryBefore = _motionSecondaryPoints[insertionIndex - 1];
      final secondaryAfter = _motionSecondaryPoints[insertionIndex];
      final x = (primaryBefore.x + primaryAfter.x) / 2;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints.take(insertionIndex),
        ChartDataPoint(
          x: x,
          y: ((primaryBefore.y + primaryAfter.y) / 2) + 8,
          label: 'Backfill',
        ),
        ..._motionPrimaryPoints.skip(insertionIndex),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints.take(insertionIndex),
        ChartDataPoint(
          x: x,
          y: ((secondaryBefore.y + secondaryAfter.y) / 2) - 6,
          label: 'Backfill',
        ),
        ..._motionSecondaryPoints.skip(insertionIndex),
      ];
    });
  }

  void _addMotionPoint() {
    setState(() {
      final nextX = _motionPrimaryPoints.last.x + 1;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints,
        ChartDataPoint(
          x: nextX,
          y: _motionPrimaryPoints.last.y + 7,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints,
        ChartDataPoint(
          x: nextX,
          y: _motionSecondaryPoints.last.y + 5,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
    });
  }

  void _removeMotionPoint() {
    if (_motionPrimaryPoints.length <= 2) return;
    setState(() {
      _motionPrimaryPoints = _motionPrimaryPoints.sublist(
        0,
        _motionPrimaryPoints.length - 1,
      );
      _motionSecondaryPoints = _motionSecondaryPoints.sublist(
        0,
        _motionSecondaryPoints.length - 1,
      );
    });
  }

  void _rollMotionWindow() {
    if (_motionPrimaryPoints.length <= 1) return;
    setState(() {
      final nextX = _motionPrimaryPoints.last.x + 1;
      _motionPrimaryPoints = [
        ..._motionPrimaryPoints.skip(1),
        ChartDataPoint(
          x: nextX,
          y: _motionPrimaryPoints.last.y + 7,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
      _motionSecondaryPoints = [
        ..._motionSecondaryPoints.skip(1),
        ChartDataPoint(
          x: nextX,
          y: _motionSecondaryPoints.last.y + 5,
          label: 'Point ${nextX.toInt()}',
        ),
      ];
    });
  }
}

class _ChartTypePreset {
  const _ChartTypePreset({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;
}

class _FeatureCoverage extends StatelessWidget {
  const _FeatureCoverage({required this.family});

  final _CartesianFamily family;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final features = switch (family) {
      _CartesianFamily.line => const [
        'Linear',
        'Bezier',
        'Monotone',
        'Stepped',
        'Markers',
        'Point labels',
        'Glow',
        'Multi-axis',
        'Entrance reveal',
        'Data-update motion',
        'Chart/data workbench',
      ],
      _CartesianFamily.area => const [
        'Layering',
        'Fill opacity',
        'Gradient fill',
        'Positive/negative baseline',
        'Interpolation',
        'Markers',
        'Glow',
        'Entrance reveal',
        'Data-update motion',
        'Chart/data workbench',
      ],
      _CartesianFamily.scatter => const [
        'Multiple cohorts',
        'Marker sizing',
        'Point styling',
        'Trend annotations',
        'Tracking tooltips',
      ],
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.checklist, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features
                    .map(
                      (feature) => Text(
                        feature,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ChartDataPoint> _offsetPoints(
  List<ChartDataPoint> points,
  double offset,
) => points
    .map((point) => ChartDataPoint(x: point.x, y: point.y + offset))
    .toList(growable: false);

const _primaryPoints = [
  ChartDataPoint(x: 0, y: 30),
  ChartDataPoint(x: 1, y: 38),
  ChartDataPoint(x: 2, y: 35),
  ChartDataPoint(x: 3, y: 48),
  ChartDataPoint(x: 4, y: 44),
  ChartDataPoint(x: 5, y: 55),
  ChartDataPoint(x: 6, y: 63),
  ChartDataPoint(x: 7, y: 58),
];

const _secondaryPoints = [
  ChartDataPoint(x: 0, y: 34),
  ChartDataPoint(x: 1, y: 36),
  ChartDataPoint(x: 2, y: 39),
  ChartDataPoint(x: 3, y: 43),
  ChartDataPoint(x: 4, y: 47),
  ChartDataPoint(x: 5, y: 51),
  ChartDataPoint(x: 6, y: 55),
  ChartDataPoint(x: 7, y: 59),
];

const _powerPoints = [
  ChartDataPoint(x: 0, y: 148),
  ChartDataPoint(x: 1, y: 162),
  ChartDataPoint(x: 2, y: 177),
  ChartDataPoint(x: 3, y: 196),
  ChartDataPoint(x: 4, y: 212),
  ChartDataPoint(x: 5, y: 201),
  ChartDataPoint(x: 6, y: 226),
  ChartDataPoint(x: 7, y: 218),
];

const _heartRatePoints = [
  ChartDataPoint(x: 0, y: 108),
  ChartDataPoint(x: 1, y: 116),
  ChartDataPoint(x: 2, y: 124),
  ChartDataPoint(x: 3, y: 137),
  ChartDataPoint(x: 4, y: 149),
  ChartDataPoint(x: 5, y: 156),
  ChartDataPoint(x: 6, y: 164),
  ChartDataPoint(x: 7, y: 168),
];

const _lactatePoints = [
  ChartDataPoint(x: 0, y: 0.9),
  ChartDataPoint(x: 1, y: 1.0),
  ChartDataPoint(x: 2, y: 1.2),
  ChartDataPoint(x: 3, y: 1.5),
  ChartDataPoint(x: 4, y: 1.9),
  ChartDataPoint(x: 5, y: 2.3),
  ChartDataPoint(x: 6, y: 2.8),
  ChartDataPoint(x: 7, y: 3.4),
];

const _baselinePoints = [
  ChartDataPoint(x: 0, y: 14),
  ChartDataPoint(x: 1, y: 9),
  ChartDataPoint(x: 2, y: 5),
  ChartDataPoint(x: 3, y: -3),
  ChartDataPoint(x: 4, y: -9),
  ChartDataPoint(x: 5, y: -16),
  ChartDataPoint(x: 6, y: -8),
  ChartDataPoint(x: 7, y: 4),
];

const _spotlightSignalPoints = [
  ChartDataPoint(x: 0, y: 52),
  ChartDataPoint(x: 1, y: 66),
  ChartDataPoint(x: 2, y: 59),
  ChartDataPoint(x: 3, y: 43),
  ChartDataPoint(x: 4, y: 34),
  ChartDataPoint(x: 5, y: 38),
  ChartDataPoint(x: 6, y: 51),
  ChartDataPoint(x: 7, y: 56),
  ChartDataPoint(x: 8, y: 48),
  ChartDataPoint(x: 9, y: 31),
  ChartDataPoint(x: 10, y: 25),
  ChartDataPoint(x: 11, y: 40),
  ChartDataPoint(x: 12, y: 54),
];

const _spotlightContextPoints = [
  ChartDataPoint(x: 0, y: 48),
  ChartDataPoint(x: 1, y: 52),
  ChartDataPoint(x: 2, y: 54),
  ChartDataPoint(x: 3, y: 55),
  ChartDataPoint(x: 4, y: 53),
  ChartDataPoint(x: 5, y: 49),
  ChartDataPoint(x: 6, y: 45),
  ChartDataPoint(x: 7, y: 42),
  ChartDataPoint(x: 8, y: 43),
  ChartDataPoint(x: 9, y: 47),
  ChartDataPoint(x: 10, y: 51),
  ChartDataPoint(x: 11, y: 54),
  ChartDataPoint(x: 12, y: 52),
];

const _pulseLivePoints = [
  ChartDataPoint(x: 0, y: 28),
  ChartDataPoint(x: 1, y: 34),
  ChartDataPoint(x: 2, y: 39),
  ChartDataPoint(x: 3, y: 48),
  ChartDataPoint(x: 4, y: 44),
  ChartDataPoint(x: 5, y: 56),
  ChartDataPoint(x: 6, y: 64),
  ChartDataPoint(x: 7, y: 58),
];

const _pulseTargetPoints = [
  ChartDataPoint(x: 0, y: 32),
  ChartDataPoint(x: 1, y: 36),
  ChartDataPoint(x: 2, y: 40),
  ChartDataPoint(x: 3, y: 44),
  ChartDataPoint(x: 4, y: 48),
  ChartDataPoint(x: 5, y: 52),
  ChartDataPoint(x: 6, y: 56),
  ChartDataPoint(x: 7, y: 60),
];

const _scatterPrimary = [
  ChartDataPoint(x: 1, y: 18),
  ChartDataPoint(x: 2, y: 24),
  ChartDataPoint(x: 3, y: 29),
  ChartDataPoint(x: 4, y: 35),
  ChartDataPoint(x: 5, y: 43),
  ChartDataPoint(x: 6, y: 48),
  ChartDataPoint(x: 7, y: 56),
  ChartDataPoint(x: 8, y: 61),
];

const _scatterSecondary = [
  ChartDataPoint(x: 1.3, y: 25),
  ChartDataPoint(x: 2.2, y: 20),
  ChartDataPoint(x: 3.4, y: 37),
  ChartDataPoint(x: 4.2, y: 31),
  ChartDataPoint(x: 5.5, y: 51),
  ChartDataPoint(x: 6.2, y: 44),
  ChartDataPoint(x: 7.4, y: 64),
];

const _scatterOutliers = [
  ChartDataPoint(x: 1.5, y: 42),
  ChartDataPoint(x: 4.8, y: 16),
  ChartDataPoint(x: 7.2, y: 75),
];
