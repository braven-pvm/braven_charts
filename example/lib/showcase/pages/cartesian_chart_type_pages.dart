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

  @override
  void dispose() {
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
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 16),
          Expanded(child: _buildChartCard()),
          const SizedBox(height: 16),
          _FeatureCoverage(family: widget.family),
        ],
      ),
    );
  }

  String get _pageTitle => switch (widget.family) {
    _CartesianFamily.line => 'Line Charts',
    _CartesianFamily.area => 'Area Charts',
    _CartesianFamily.scatter => 'Scatter Charts',
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

  Widget _buildPresetPicker() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a ${_pageTitle.toLowerCase()} example',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
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
                  setState(() => _presetIndex = selection.single);
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: BravenChartPlus(
            key: ValueKey('${widget.family.name}-chart-preset-$_presetIndex'),
            series: _buildSeries(),
            annotations: _buildAnnotations(),
            theme: options.theme ?? ChartTheme.light,
            showLegend: options.showLegend,
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
          ),
        );
      },
    );
  }

  String get _chartSummary => switch (widget.family) {
    _CartesianFamily.line =>
      '${_buildSeries().length} series · ${_interpolation.name} · tracking enabled',
    _CartesianFamily.area =>
      '${_buildSeries().length} series · ${(_fillOpacity * 100).round()}% fill · ${_interpolation.name}',
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
      if (widget.family != _CartesianFamily.scatter)
        EnumOption<LineInterpolation>(
          label: 'Interpolation',
          value: _interpolation,
          values: LineInterpolation.values,
          onChanged: (value) => setState(() => _interpolation = value),
        ),
      if (widget.family != _CartesianFamily.scatter)
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
      if (widget.family != _CartesianFamily.scatter)
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
      if (widget.family == _CartesianFamily.area)
        BoolOption(
          label: 'Use baseline fills',
          value: _showBaselineFill,
          onChanged: (value) => setState(() => _showBaselineFill = value),
          subtitle: 'Apply positive and negative fills in the baseline preset',
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
      StandardChartOptions(
        controller: _optionsController,
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
    );
  }

  List<ChartSeries> _buildAreaSeries() {
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
  }) {
    return AreaChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      interpolation: _interpolation,
      strokeWidth: _strokeWidth,
      fillOpacity: _fillOpacity,
      lineGlow: _lineGlow,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointLabels: DataPointLabelConfig(show: _showPointLabels),
    );
  }

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
    });
    _optionsController.update(const ChartOptions(showDataMarkers: true));
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
      ],
      _CartesianFamily.area => const [
        'Layering',
        'Fill opacity',
        'Positive/negative baseline',
        'Interpolation',
        'Markers',
        'Glow',
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
