// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _HeatmapPreset {
  activity,
  temperature,
  threshold,
  calendar,
  correlation,
  dense,
}

enum _HeatmapPalette { ocean, sunset, viridis, graphite }

enum _HeatmapMotion { fade, scale, none }

class HeatmapChartsPage extends StatefulWidget {
  const HeatmapChartsPage({super.key});

  @override
  State<HeatmapChartsPage> createState() => _HeatmapChartsPageState();
}

class _HeatmapChartsPageState extends State<HeatmapChartsPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();

  _HeatmapPreset _preset = _HeatmapPreset.activity;
  _HeatmapPalette _palette = _HeatmapPalette.ocean;
  bool _showValues = true;
  bool _showColorLegend = true;
  bool _reverseScale = false;
  bool _clampScale = true;
  double _gapFraction = 0.06;
  double _cornerRadius = 3;
  double _domainPadding = 0;
  double _midpointOffset = 0;
  Color _missingColor = const Color(0xFFE2E8F0);
  _HeatmapMotion _motion = _HeatmapMotion.scale;
  HeatmapEntranceOrder _entranceOrder = HeatmapEntranceOrder.row;
  bool _animateUpdates = true;
  int _dataRevision = 0;

  @override
  void initState() {
    super.initState();
    final requestedPreset = Uri.base.queryParameters['preset']?.toLowerCase();
    for (final preset in _HeatmapPreset.values) {
      if (preset.name == requestedPreset) {
        _preset = preset;
        break;
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Heatmap Charts',
      subtitle:
          'Encode an independent measured value across a native Cartesian matrix',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('heatmap-replay-entrance'),
          onPressed: _motion == _HeatmapMotion.none
              ? null
              : _chartController.replaySeriesEntrance,
          icon: const Icon(Icons.play_arrow_outlined, size: 18),
          label: const Text('Replay entrance'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('heatmap-animate-update'),
          onPressed: _animateUpdates
              ? () => setState(() => _dataRevision++)
              : null,
          icon: const Icon(Icons.autorenew, size: 18),
          label: const Text('Animate update'),
        ),
      ],
      chart: ListView(
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 620,
                    child: BravenChartWorkbench(
                      key: const ValueKey('heatmap-workbench'),
                      chartController: _chartController,
                      workbenchController: _workbenchController,
                      availableDisplayModes: const {
                        ChartDisplayMode.chart,
                        ChartDisplayMode.data,
                        ChartDisplayMode.split,
                        ChartDisplayMode.source,
                      },
                      documentOptions: ChartDocumentExtractOptions(
                        documentId: 'heatmap-${_preset.name}-showcase',
                        includeViewState: true,
                        dataStorage: ChartDataStorage.inlineColumns,
                      ),
                      tableOptions: const ChartTableOptions(
                        includeMetadata: true,
                      ),
                      tableRefreshPolicy:
                          ChartTableRefreshPolicy.onDocumentRevision,
                      sourceOptions: const ChartDartSourceOptions(
                        variableName: 'heatmapChart',
                      ),
                      splitBreakpoint: 760,
                      splitAxis: Axis.horizontal,
                      splitGap: 8,
                      splitRatio: 0.56,
                      minimumChartPaneExtent: 320,
                      minimumTablePaneExtent: 360,
                      maximumAutoTablePaneExtent: 640,
                      autoFitTablePane: true,
                      chartBuilder: (context, controller) =>
                          _buildChart(controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _HeatmapCoverageStrip(),
        ],
      ),
      optionsChildren: [
        OptionSection(
          title: 'Colour scale',
          icon: Icons.gradient_outlined,
          children: [
            EnumOption<_HeatmapPalette>(
              label: 'Palette',
              value: _palette,
              values: _HeatmapPalette.values,
              labelBuilder: (value) => switch (value) {
                _HeatmapPalette.ocean => 'Ocean',
                _HeatmapPalette.sunset => 'Sunset',
                _HeatmapPalette.viridis => 'Viridis',
                _HeatmapPalette.graphite => 'Graphite',
              },
              onChanged: (value) => setState(() => _palette = value),
            ),
            BoolOption(
              label: 'Reverse palette',
              value: _reverseScale,
              onChanged: (value) => setState(() => _reverseScale = value),
            ),
            if (_preset != _HeatmapPreset.threshold)
              BoolOption(
                label: 'Clamp to domain',
                value: _clampScale,
                onChanged: (value) => setState(() => _clampScale = value),
              ),
            if (_preset != _HeatmapPreset.threshold)
              _slider(
                label: 'Domain padding',
                value: _domainPadding,
                minimum: 0,
                maximum: _domainPaddingMaximum,
                onChanged: (value) => setState(() => _domainPadding = value),
              ),
            if (_usesMidpoint)
              _slider(
                label: 'Midpoint offset',
                value: _midpointOffset,
                minimum: -_midpointOffsetMaximum,
                maximum: _midpointOffsetMaximum,
                onChanged: (value) => setState(() => _midpointOffset = value),
              ),
            ColorOption(
              label: 'Missing cell',
              value: _missingColor,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFCBD5E1),
                Color(0xFFFEF3C7),
                Color(0xFFFCE7F3),
              ],
              keyPrefix: 'heatmap-missing-color',
              onChanged: (value) => setState(() => _missingColor = value),
            ),
            BoolOption(
              label: 'Show colour legend',
              value: _showColorLegend,
              onChanged: (value) => setState(() => _showColorLegend = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Cell presentation',
          icon: Icons.grid_view_outlined,
          children: [
            BoolOption(
              label: 'Show cell values',
              value: _showValues,
              onChanged: (value) => setState(() => _showValues = value),
            ),
            _slider(
              label: 'Cell gap',
              value: _gapFraction,
              minimum: 0,
              maximum: 0.3,
              onChanged: (value) => setState(() => _gapFraction = value),
            ),
            _slider(
              label: 'Corner radius',
              value: _cornerRadius,
              minimum: 0,
              maximum: 14,
              onChanged: (value) => setState(() => _cornerRadius = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Motion',
          icon: Icons.animation_outlined,
          children: [
            EnumOption<_HeatmapMotion>(
              label: 'Entrance',
              value: _motion,
              values: _HeatmapMotion.values,
              labelBuilder: (value) => switch (value) {
                _HeatmapMotion.fade => 'Fade',
                _HeatmapMotion.scale => 'Fade + scale',
                _HeatmapMotion.none => 'None',
              },
              onChanged: (value) => setState(() => _motion = value),
            ),
            if (_motion != _HeatmapMotion.none)
              EnumOption<HeatmapEntranceOrder>(
                label: 'Reveal order',
                value: _entranceOrder,
                values: HeatmapEntranceOrder.values,
                labelBuilder: (value) => switch (value) {
                  HeatmapEntranceOrder.simultaneous => 'Simultaneous',
                  HeatmapEntranceOrder.row => 'By row',
                  HeatmapEntranceOrder.column => 'By column',
                  HeatmapEntranceOrder.radial => 'From centre',
                },
                onChanged: (value) => setState(() => _entranceOrder = value),
              ),
            BoolOption(
              label: 'Animate data updates',
              value: _animateUpdates,
              onChanged: (value) => setState(() => _animateUpdates = value),
            ),
            if (_motion != _HeatmapMotion.none)
              ActionButton(
                key: const ValueKey('heatmap-options-replay'),
                label: 'Replay entrance',
                icon: Icons.replay_outlined,
                onPressed: _chartController.replaySeriesEntrance,
              ),
            if (_animateUpdates)
              ActionButton(
                key: const ValueKey('heatmap-options-update'),
                label: 'Update stable values',
                icon: Icons.autorenew,
                onPressed: () => setState(() => _dataRevision++),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(BravenChartController controller) {
    final series = _series;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BravenChartPlus(
            key: ValueKey('heatmap-chart-${_preset.name}'),
            bravenChartController: controller,
            series: [series],
            showLegend: false,
            grid: const GridConfig(horizontal: false, vertical: false),
            xAxisConfig: _preset == _HeatmapPreset.dense
                ? const XAxisConfig(
                    label: 'Sample',
                    min: 80,
                    max: 120,
                    tickCount: 9,
                  )
                : XAxisConfig(
                    label: _xAxisLabel,
                    categoryAxis: CategoryAxisConfig(
                      categories: _columnLabels,
                      minimumCategoryExtent: 42,
                    ),
                  ),
            yAxis: _preset == _HeatmapPreset.dense
                ? YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Channel',
                    min: 30,
                    max: 60,
                    tickCount: 7,
                  )
                : YAxisConfig(
                    position: YAxisPosition.left,
                    label: _yAxisLabel,
                    categoryAxis: CategoryAxisConfig(
                      categories: _rowLabels,
                      minimumCategoryExtent: 34,
                      maximumLabelExtent: 78,
                    ),
                  ),
            interactionConfig: const InteractionConfig(
              tooltip: TooltipConfig(enabled: true),
              enableZoom: true,
              enablePan: true,
            ),
            annotations: _annotations,
            showXScrollbar: true,
            showYScrollbar: _preset == _HeatmapPreset.dense,
          ),
        ),
        const SizedBox(height: 8),
        HeatmapColorLegend(series: series),
      ],
    );
  }

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
              'Choose a heatmap example',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice(
                  _HeatmapPreset.activity,
                  'Activity matrix',
                  Icons.calendar_view_week_outlined,
                ),
                _choice(
                  _HeatmapPreset.temperature,
                  'Temperature',
                  Icons.thermostat_outlined,
                ),
                _choice(
                  _HeatmapPreset.threshold,
                  'Service health',
                  Icons.monitor_heart_outlined,
                ),
                _choice(
                  _HeatmapPreset.calendar,
                  'Calendar month',
                  Icons.calendar_month_outlined,
                ),
                _choice(
                  _HeatmapPreset.correlation,
                  'Correlation',
                  Icons.hub_outlined,
                ),
                _choice(
                  _HeatmapPreset.dense,
                  'Dense viewport',
                  Icons.blur_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              switch (_preset) {
                _HeatmapPreset.activity =>
                  'A sequential scale reveals the busiest weekday and hour combinations.',
                _HeatmapPreset.temperature =>
                  'A diverging scale keeps the comfort midpoint semantically stable.',
                _HeatmapPreset.threshold =>
                  'Discrete thresholds turn operational values into named status bands.',
                _HeatmapPreset.calendar =>
                  'Explicit missing cells preserve the shape of an incomplete calendar month.',
                _HeatmapPreset.correlation =>
                  'A square diverging matrix exposes positive and negative relationships around zero.',
                _HeatmapPreset.dense =>
                  'A 30,000-cell sparse field paints and hits only the visible viewport.',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(_HeatmapPreset preset, String label, IconData icon) {
    return ChoiceChip(
      selected: _preset == preset,
      onSelected: (_) => setState(() {
        _preset = preset;
        _domainPadding = 0;
        _midpointOffset = 0;
        _dataRevision = 0;
      }),
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double minimum,
    required double maximum,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value.toStringAsFixed(value < 1 ? 2 : 0)),
            ],
          ),
        ),
        Slider(value: value, min: minimum, max: maximum, onChanged: onChanged),
      ],
    );
  }

  HeatmapChartSeries get _series => HeatmapChartSeries(
    id: 'heatmap-${_preset.name}',
    name: _title,
    points: _points,
    colorScale: _scale,
    unit: _unit,
    showCellLabels: _showValues && _preset != _HeatmapPreset.dense,
    cellLabelFontSize: 10.5,
    gapFraction: _gapFraction,
    cornerRadius: _cornerRadius,
    borderColor: const Color(0x33FFFFFF),
    borderWidth: 0.7,
    animation: HeatmapAnimationStyle(
      entranceMode: switch (_motion) {
        _HeatmapMotion.fade => HeatmapEntranceMode.fade,
        _HeatmapMotion.scale => HeatmapEntranceMode.scale,
        _HeatmapMotion.none => HeatmapEntranceMode.none,
      },
      entranceOrder: _entranceOrder,
      animateDataUpdates: _animateUpdates,
    ),
  );

  List<HeatmapDataPoint> get _points => [
    for (final cell in _basePoints)
      if (cell.isMissing)
        cell
      else
        cell.copyWith(
          value:
              cell.value! +
              _dataRevision *
                  (1 + ((cell.x * 3 + cell.y * 5).round().abs() % 5)) *
                  _updateStep,
        ),
  ];

  List<HeatmapDataPoint> get _basePoints {
    if (_preset == _HeatmapPreset.dense) {
      return [
        for (var row = 0; row < 120; row++)
          for (var column = 0; column < 250; column++)
            if ((row * 17 + column * 31) % 29 != 0)
              HeatmapDataPoint(
                x: column.toDouble(),
                y: row.toDouble(),
                value:
                    50 +
                    34 *
                        (0.58 * _wave(column / 13) +
                            0.42 * _wave((row + column) / 19)),
                pointKey: 'dense-$row-$column',
                label: 'Channel $row · sample $column',
              ),
      ];
    }
    if (_preset == _HeatmapPreset.calendar) {
      const values = <double?>[
        null,
        null,
        18,
        19,
        21,
        23,
        24,
        22,
        20,
        18,
        17,
        19,
        22,
        25,
        27,
        28,
        24,
        21,
        20,
        18,
        17,
        16,
        18,
        21,
        23,
        22,
        20,
        19,
        17,
        16,
        15,
        null,
        null,
        null,
        null,
      ];
      return [
        for (var index = 0; index < values.length; index++)
          if (values[index] == null)
            HeatmapDataPoint.missing(
              x: (index % 7).toDouble(),
              y: (index ~/ 7).toDouble(),
              pointKey: 'calendar-$index',
              label: 'Outside July',
            )
          else
            HeatmapDataPoint(
              x: (index % 7).toDouble(),
              y: (index ~/ 7).toDouble(),
              value: values[index]!,
              pointKey: 'calendar-$index',
              label: 'July ${index - 1} · ${values[index]!.toInt()} °C',
            ),
      ];
    }
    if (_preset == _HeatmapPreset.correlation) {
      const values = [
        [1.0, 0.82, 0.44, -0.28, -0.61, 0.18],
        [0.82, 1.0, 0.56, -0.12, -0.48, 0.34],
        [0.44, 0.56, 1.0, 0.26, -0.22, 0.71],
        [-0.28, -0.12, 0.26, 1.0, 0.63, 0.39],
        [-0.61, -0.48, -0.22, 0.63, 1.0, 0.11],
        [0.18, 0.34, 0.71, 0.39, 0.11, 1.0],
      ];
      return [
        for (var row = 0; row < values.length; row++)
          for (var column = 0; column < values[row].length; column++)
            HeatmapDataPoint(
              x: column.toDouble(),
              y: row.toDouble(),
              value: values[row][column],
              pointKey: 'correlation-$row-$column',
              label: '${_rowLabels[row]} × ${_columnLabels[column]}',
            ),
      ];
    }
    final values = switch (_preset) {
      _HeatmapPreset.activity => const [
        [18.0, 22, 35, 48, 72, 54, 31, 26, 20, 14, 9, 6],
        [16.0, 27, 42, 61, 84, 69, 50, 44, 33, 19, 12, 8],
        [12.0, 21, 38, 57, 76, 91, 67, 53, 37, 24, 15, 10],
        [14.0, 25, 46, 73, 96, 88, 71, 59, 41, 29, 18, 11],
        [20.0, 31, 51, 79, 100, 94, 78, 62, 45, 32, 22, 15],
        [28.0, 36, 49, 63, 82, 76, 66, 58, 47, 38, 30, 24],
        [24.0, 29, 37, 45, 58, 55, 49, 43, 36, 30, 26, 21],
      ],
      _HeatmapPreset.temperature => const [
        [12.0, 11, 10, 11, 13, 16, 19, 22, 24, 23, 19, 15],
        [11.0, 10, 9, 10, 12, 15, 18, 21, 23, 22, 18, 14],
        [9.0, 8, 8, 9, 11, 14, 18, 22, 26, 25, 20, 15],
        [10.0, 9, 9, 10, 13, 17, 21, 25, 28, 27, 22, 17],
        [13.0, 12, 11, 12, 14, 18, 22, 26, 29, 28, 23, 18],
        [14.0, 13, 12, 13, 15, 19, 23, 27, 30, 29, 24, 19],
        [12.0, 11, 10, 11, 14, 18, 22, 25, 27, 26, 22, 17],
      ],
      _HeatmapPreset.threshold => const [
        [99.9, 99.8, 99.7, 99.4, 99.2, 99.8, 99.9, 100, 99.7, 99.8, 99.9, 100],
        [
          99.8,
          99.5,
          98.8,
          97.9,
          96.7,
          98.4,
          99.3,
          99.7,
          99.8,
          99.9,
          99.7,
          99.8,
        ],
        [
          99.9,
          99.7,
          99.6,
          99.1,
          98.9,
          99.2,
          99.5,
          99.8,
          99.9,
          99.7,
          99.8,
          99.9,
        ],
        [
          100.0,
          99.9,
          99.8,
          99.7,
          99.5,
          99.6,
          99.8,
          99.9,
          100,
          99.9,
          99.8,
          99.9,
        ],
      ],
      _HeatmapPreset.calendar ||
      _HeatmapPreset.correlation => const <List<double>>[],
      _HeatmapPreset.dense => const <List<double>>[],
    };
    return [
      for (var row = 0; row < values.length; row++)
        for (var column = 0; column < values[row].length; column++)
          HeatmapDataPoint(
            x: column.toDouble(),
            y: row.toDouble(),
            value: values[row][column].toDouble(),
            pointKey: '${_preset.name}-$row-$column',
            label: '${_rowLabels[row]} · ${_columnLabels[column]}',
          ),
    ];
  }

  List<ChartAnnotation> get _annotations => switch (_preset) {
    _HeatmapPreset.activity => [
      RangeAnnotation(
        id: 'working-hours',
        startX: 3.5,
        endX: 8.5,
        startY: -0.45,
        endY: 6.45,
        label: 'Working hours',
        fillColor: const Color(0x0F2563EB),
        borderColor: const Color(0x662563EB),
      ),
    ],
    _HeatmapPreset.threshold => [
      RangeAnnotation(
        id: 'incident-window',
        startX: 2.5,
        endX: 5.5,
        startY: -0.45,
        endY: 3.45,
        label: 'Incident window',
        fillColor: const Color(0x12DC2626),
        borderColor: const Color(0x66DC2626),
      ),
    ],
    _ => const <ChartAnnotation>[],
  };

  double get _updateStep => switch (_preset) {
    _HeatmapPreset.correlation => 0.015,
    _HeatmapPreset.threshold => 0.02,
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => 0.25,
    _ => 0.8,
  };

  HeatmapColorScale get _scale => switch (_preset) {
    _HeatmapPreset.activity => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 0 - _domainPadding,
      maximumValue: 100 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Activity',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.temperature => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: 20 + _midpointOffset,
      minimumValue: 8 - _domainPadding,
      maximumValue: 30 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Temperature',
      unit: '°C',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.threshold => HeatmapColorScale.threshold(
      thresholds: const [98, 99.5],
      colors: _thresholdColors,
      bandLabels: const ['Degraded', 'Watch', 'Healthy'],
      reverse: _reverseScale,
      missingColor: _missingColor,
      label: 'Availability',
      unit: '%',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.calendar => HeatmapColorScale.sequential(
      colors: _sequentialColors,
      minimumValue: 15 - _domainPadding,
      maximumValue: 28 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Daily maximum',
      unit: '°C',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.correlation => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: _midpointOffset,
      minimumValue: -1 - _domainPadding,
      maximumValue: 1 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Correlation',
      showLegend: _showColorLegend,
    ),
    _HeatmapPreset.dense => HeatmapColorScale.diverging(
      lowColor: _divergingColors[0],
      midpointColor: _divergingColors[1],
      highColor: _divergingColors[2],
      midpoint: 50 + _midpointOffset,
      minimumValue: 16 - _domainPadding,
      maximumValue: 84 + _domainPadding,
      reverse: _reverseScale,
      clamp: _clampScale,
      missingColor: _missingColor,
      label: 'Signal',
      unit: '%',
      showLegend: _showColorLegend,
    ),
  };

  String get _title => switch (_preset) {
    _HeatmapPreset.activity => 'Product activity by day and hour',
    _HeatmapPreset.temperature => 'Weekly temperature profile',
    _HeatmapPreset.threshold => 'Service availability matrix',
    _HeatmapPreset.calendar => 'Daily temperature in July',
    _HeatmapPreset.correlation => 'Product metric correlation',
    _HeatmapPreset.dense => 'Dense signal viewport',
  };

  String get _subtitle => switch (_preset) {
    _HeatmapPreset.activity => '7 days · 12 time slots · sequential scale',
    _HeatmapPreset.temperature => '7 days · diverging around 20 °C',
    _HeatmapPreset.threshold => '4 services · discrete operational bands',
    _HeatmapPreset.calendar =>
      '5 calendar weeks · explicit missing cells · sequential scale',
    _HeatmapPreset.correlation =>
      '6 metrics · square matrix · diverging around zero',
    _HeatmapPreset.dense =>
      '30,000 source positions · sparse gaps · viewport-indexed rendering',
  };

  List<String> get _rowLabels => switch (_preset) {
    _HeatmapPreset.activity || _HeatmapPreset.temperature => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ],
    _HeatmapPreset.threshold => const ['API', 'Web', 'Jobs', 'Storage'],
    _HeatmapPreset.calendar => const [
      'Week 1',
      'Week 2',
      'Week 3',
      'Week 4',
      'Week 5',
    ],
    _HeatmapPreset.correlation => const [
      'Revenue',
      'Orders',
      'Sessions',
      'Latency',
      'Errors',
      'Retention',
    ],
    _HeatmapPreset.dense => const [],
  };

  List<String> get _columnLabels => switch (_preset) {
    _HeatmapPreset.calendar => const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ],
    _HeatmapPreset.correlation => _rowLabels,
    _ => const [
      '00',
      '02',
      '04',
      '06',
      '08',
      '10',
      '12',
      '14',
      '16',
      '18',
      '20',
      '22',
    ],
  };

  String? get _unit => switch (_preset) {
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => '°C',
    _HeatmapPreset.correlation => null,
    _ => '%',
  };
  String get _xAxisLabel => switch (_preset) {
    _HeatmapPreset.calendar => 'Day of week',
    _HeatmapPreset.correlation => 'Metric',
    _ => 'Hour',
  };
  String get _yAxisLabel => switch (_preset) {
    _HeatmapPreset.threshold => 'Service',
    _HeatmapPreset.calendar => 'Week',
    _HeatmapPreset.correlation => 'Metric',
    _ => 'Day',
  };

  bool get _usesMidpoint =>
      _preset == _HeatmapPreset.temperature ||
      _preset == _HeatmapPreset.correlation ||
      _preset == _HeatmapPreset.dense;

  double get _domainPaddingMaximum => switch (_preset) {
    _HeatmapPreset.correlation => 0.5,
    _HeatmapPreset.temperature || _HeatmapPreset.calendar => 10,
    _ => 25,
  };

  double get _midpointOffsetMaximum => switch (_preset) {
    _HeatmapPreset.correlation => 0.5,
    _HeatmapPreset.temperature => 6,
    _ => 20,
  };

  List<Color> get _sequentialColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFFE0F2FE),
      Color(0xFF67E8F9),
      Color(0xFF0891B2),
      Color(0xFF164E63),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFFFFF7ED),
      Color(0xFFFDBA74),
      Color(0xFFEA580C),
      Color(0xFF7C2D12),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFF31688E),
      Color(0xFF35B779),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFFF8FAFC),
      Color(0xFFCBD5E1),
      Color(0xFF64748B),
      Color(0xFF0F172A),
    ],
  };

  List<Color> get _divergingColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFF2563EB),
      Color(0xFFF8FAFC),
      Color(0xFFEA580C),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFF7C3AED),
      Color(0xFFFFFBEB),
      Color(0xFFE11D48),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFFF8FAFC),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFF334155),
      Color(0xFFF8FAFC),
      Color(0xFF0F172A),
    ],
  };

  List<Color> get _thresholdColors => switch (_palette) {
    _HeatmapPalette.ocean => const [
      Color(0xFFDC2626),
      Color(0xFFF59E0B),
      Color(0xFF16A34A),
    ],
    _HeatmapPalette.sunset => const [
      Color(0xFF7C3AED),
      Color(0xFFF97316),
      Color(0xFFFDE047),
    ],
    _HeatmapPalette.viridis => const [
      Color(0xFF440154),
      Color(0xFF21918C),
      Color(0xFFFDE725),
    ],
    _HeatmapPalette.graphite => const [
      Color(0xFF334155),
      Color(0xFF94A3B8),
      Color(0xFFE2E8F0),
    ],
  };

  static double _wave(num radians) {
    final value = radians.toDouble();
    // A compact deterministic approximation is sufficient for showcase data
    // and avoids making the example depend on a random seed.
    final wrapped = value % 6.283185307179586;
    if (wrapped < 1.5707963267948966) return wrapped / 1.5707963267948966;
    if (wrapped < 4.71238898038469) {
      return 2 - wrapped / 1.5707963267948966;
    }
    return wrapped / 1.5707963267948966 - 4;
  }
}

class _HeatmapCoverageStrip extends StatelessWidget {
  const _HeatmapCoverageStrip();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _CoverageItem(label: 'Native Cartesian cells'),
            _CoverageItem(label: 'Sequential scale'),
            _CoverageItem(label: 'Diverging midpoint'),
            _CoverageItem(label: 'Threshold bands'),
            _CoverageItem(label: 'Tooltips + selection'),
            _CoverageItem(label: 'Sparse/missing identity'),
            _CoverageItem(label: 'Viewport culling + indexed hit'),
          ],
        ),
      ),
    );
  }
}

class _CoverageItem extends StatelessWidget {
  const _CoverageItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.check_circle_outline,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}
