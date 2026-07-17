// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _BarLabPreset {
  capacity,
  rods,
  gradient,
  signed,
  overlay,
  offset,
  range,
  waterfall,
  horizontal,
  axes,
  motion,
  states,
  stacked,
  normalized,
}

extension on _BarLabPreset {
  String get label => switch (this) {
    _BarLabPreset.capacity => 'Capacity',
    _BarLabPreset.rods => 'Rods',
    _BarLabPreset.gradient => 'Gradient',
    _BarLabPreset.signed => 'Signed',
    _BarLabPreset.overlay => 'Overlay',
    _BarLabPreset.offset => 'Offset',
    _BarLabPreset.range => 'Range',
    _BarLabPreset.waterfall => 'Waterfall',
    _BarLabPreset.horizontal => 'Horizontal',
    _BarLabPreset.axes => 'Axes',
    _BarLabPreset.motion => 'Motion',
    _BarLabPreset.states => 'States',
    _BarLabPreset.stacked => 'Stacked',
    _BarLabPreset.normalized => '100%',
  };

  IconData get icon => switch (this) {
    _BarLabPreset.capacity => Icons.stacked_bar_chart,
    _BarLabPreset.rods => Icons.equalizer,
    _BarLabPreset.gradient => Icons.gradient,
    _BarLabPreset.signed => Icons.swap_vert,
    _BarLabPreset.overlay => Icons.layers_outlined,
    _BarLabPreset.offset => Icons.compare_arrows,
    _BarLabPreset.range => Icons.height,
    _BarLabPreset.waterfall => Icons.waterfall_chart,
    _BarLabPreset.horizontal => Icons.align_horizontal_left,
    _BarLabPreset.axes => Icons.straighten,
    _BarLabPreset.motion => Icons.animation,
    _BarLabPreset.states => Icons.touch_app_outlined,
    _BarLabPreset.stacked => Icons.stacked_bar_chart,
    _BarLabPreset.normalized => Icons.percent,
  };
}

/// Interactive review surface for the modern bar geometry and style system.
class BarLabPage extends StatefulWidget {
  const BarLabPage({super.key});

  @override
  State<BarLabPage> createState() => _BarLabPageState();
}

class _BarLabPageState extends State<BarLabPage> {
  final BravenChartController _chartController = BravenChartController();
  static const _dayCategories = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _medalCategories = ['CN', 'US', 'JP', 'AU', 'FR'];
  static const _waterfallCategories = [
    'Opening',
    'New sales',
    'Expansion',
    'Churn',
    'Costs',
    'Other',
    'Net',
  ];
  static const _channelCategories = [
    'Enterprise',
    'Online',
    'Partners',
    'Mid-market',
    'Retail',
    'Direct',
  ];
  static const _medalColors = <Color>[
    Color(0xFF1F77B4),
    Color(0xFFC44FEA),
    Color(0xFF5149C6),
    Color(0xFF2CA5E8),
    Color(0xFFD90429),
  ];
  static const _seriesColors = <Color>[
    Color(0xFF168AAD),
    Color(0xFFF9735B),
    Color(0xFF6D5BD0),
    Color(0xFFE5A11A),
    Color(0xFF2F80ED),
    Color(0xFF34A853),
    Color(0xFFD94F8A),
    Color(0xFF8E6C4A),
    Color(0xFF00A6A6),
    Color(0xFF7A8B2E),
    Color(0xFFC65D21),
    Color(0xFF526D82),
  ];

  _BarLabPreset _preset = _BarLabPreset.capacity;
  int _seriesCount = 2;
  int _stackGroupCount = 1;
  BarLayoutMode _layoutMode = BarLayoutMode.grouped;
  BarOrientation _orientation = BarOrientation.vertical;
  double _barWidth = 0.72;
  double _barGap = 4;
  double _overlayWidthStep = 22;
  double _overlayOffsetStep = 0;
  double _cornerRadius = 8;
  bool _showTracks = true;
  bool _showGradient = false;
  bool _showBorder = false;
  bool _showLabels = true;
  bool _showConnectors = true;
  BarCornerRadiusPolicy _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
  BarLabelPosition _labelPosition = BarLabelPosition.auto;
  double _labelEdgeOffset = 8;
  double _dimmedOpacity = 0.42;
  int _motionRevision = 0;
  double _motionDurationMs = 650;
  bool _animateBars = true;

  @override
  void initState() {
    super.initState();
    _chartController.addListener(_onChartInteractionChanged);
    final requestedPreset = Uri.base.queryParameters['preset'];
    for (final preset in _BarLabPreset.values) {
      if (preset.name == requestedPreset) {
        _preset = preset;
        _setPresetValues(preset);
        break;
      }
    }
    final requestedSeries = int.tryParse(
      Uri.base.queryParameters['series'] ?? '',
    );
    if (requestedSeries != null) {
      _seriesCount = requestedSeries.clamp(1, _seriesColors.length);
    }
    final requestedLayout = Uri.base.queryParameters['layout'];
    for (final mode in BarLayoutMode.values) {
      if (mode.name == requestedLayout && _supportsLayout(_preset, mode)) {
        _layoutMode = mode;
        break;
      }
    }
    final requestedGroups = int.tryParse(
      Uri.base.queryParameters['groups'] ?? '',
    );
    if (requestedGroups != null) {
      _stackGroupCount = requestedGroups.clamp(1, _seriesCount);
    }
    final requestedCorners = Uri.base.queryParameters['corners'];
    for (final policy in BarCornerRadiusPolicy.values) {
      if (policy.name == requestedCorners) {
        _cornerPolicy = policy;
        break;
      }
    }
  }

  @override
  void dispose() {
    _chartController
      ..removeListener(_onChartInteractionChanged)
      ..dispose();
    super.dispose();
  }

  void _onChartInteractionChanged() {
    if (mounted && _preset == _BarLabPreset.states) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Bar Lab',
      subtitle: 'Build expressive bars from shared, precise geometry',
      actions: [
        OutlinedButton.icon(
          onPressed: _resetPreset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset style'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 16),
          Expanded(child: _buildChartCard()),
        ],
      ),
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
            Wrap(
              key: const ValueKey('bar-lab-preset-wrap'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in _BarLabPreset.values)
                  ChoiceChip(
                    key: ValueKey('bar-lab-preset-${preset.name}'),
                    showCheckmark: false,
                    selected: preset == _preset,
                    onSelected: (_) => _applyPreset(preset),
                    avatar: Icon(
                      preset.icon,
                      size: 17,
                      color: preset == _preset
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(preset.label),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: preset == _preset
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: preset == _preset
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    selectedColor: theme.colorScheme.secondaryContainer,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _presetDescription(),
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
    final lastCategory = _categories.length - 1;
    final baseTheme = ChartTheme.light;
    final chart = BravenChartPlus(
      bravenChartController: _chartController,
      theme: baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          dataUpdateDuration: Duration(milliseconds: _motionDurationMs.round()),
          dataUpdateCurve: Curves.easeInOutCubic,
        ),
      ),
      series: _buildSeries(),
      showLegend: _preset != _BarLabPreset.waterfall,
      normalizationMode: _preset == _BarLabPreset.axes
          ? NormalizationMode.perSeries
          : null,
      maxAxesPerSide: 3,
      grid: GridConfig(
        horizontal: _orientation == BarOrientation.vertical,
        vertical: _orientation == BarOrientation.horizontal,
      ),
      xAxisConfig: XAxisConfig(
        label: _preset == _BarLabPreset.offset
            ? 'Country'
            : _preset == _BarLabPreset.waterfall
            ? 'Stage'
            : _preset == _BarLabPreset.horizontal ||
                  _preset == _BarLabPreset.axes
            ? 'Channel'
            : 'Day',
        min: _orientation == BarOrientation.horizontal ? -1 : -0.6,
        max:
            lastCategory +
            (_orientation == BarOrientation.horizontal ? 1 : 0.6),
        renderMin: 0,
        renderMax: lastCategory.toDouble(),
        tickCount: _categories.length,
        labelFormatter: _categoryLabel,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: _preset == _BarLabPreset.offset
            ? 'Gold medals'
            : _preset == _BarLabPreset.range
            ? 'Temperature (°C)'
            : _preset == _BarLabPreset.waterfall
            ? 'Cash flow (thousands)'
            : _preset == _BarLabPreset.horizontal
            ? 'Revenue (thousands)'
            : _preset == _BarLabPreset.axes
            ? 'Independent values'
            : _layoutMode == BarLayoutMode.normalizedStacked
            ? 'Share of total (%)'
            : _preset == _BarLabPreset.signed
            ? 'Net change'
            : 'Value',
        min: _layoutMode == BarLayoutMode.normalizedStacked
            ? (_preset == _BarLabPreset.signed ? -110 : 0)
            : (_preset == _BarLabPreset.signed ||
                  _preset == _BarLabPreset.range ||
                  _preset == _BarLabPreset.waterfall)
            ? null
            : 0,
        max: _layoutMode == BarLayoutMode.normalizedStacked ? 110 : null,
        tickCount: 7,
      ),
      interactionConfig: InteractionConfig(
        tooltip: const TooltipConfig(),
        crosshair: CrosshairConfig(
          mode: _orientation == BarOrientation.horizontal
              ? CrosshairMode.both
              : CrosshairMode.vertical,
          displayMode: _orientation == BarOrientation.horizontal
              ? CrosshairDisplayMode.tracking
              : CrosshairDisplayMode.auto,
        ),
      ),
    );
    return ChartCard(
      title: _presetTitle(),
      subtitle: _chartSummary(),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: _preset == _BarLabPreset.waterfall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWaterfallLegend(),
                const SizedBox(height: 8),
                Expanded(child: chart),
              ],
            )
          : chart,
    );
  }

  Widget _buildWaterfallLegend() => const Padding(
    padding: EdgeInsets.only(left: 52, right: 8),
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _BarLabLegendItem(color: Color(0xFF168AAD), label: 'Increase'),
        _BarLabLegendItem(color: Color(0xFFE15B64), label: 'Decrease'),
        _BarLabLegendItem(color: Color(0xFF5149C6), label: 'Total'),
      ],
    ),
  );

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Composition',
      icon: Icons.view_week_outlined,
      children: [
        IntSliderOption(
          label: 'Series count',
          value: _seriesCount,
          min: 1,
          max: _seriesColors.length,
          onChanged: (value) => setState(() => _seriesCount = value),
        ),
        EnumOption<BarLayoutMode>(
          label: 'Layout',
          value: _layoutMode,
          values: BarLayoutMode.values
              .where((mode) => _supportsLayout(_preset, mode))
              .toList(growable: false),
          labelBuilder: _layoutLabel,
          onChanged: (value) => setState(() => _layoutMode = value),
        ),
        EnumOption<BarOrientation>(
          label: 'Orientation',
          value: _orientation,
          values: BarOrientation.values,
          labelBuilder: (value) => switch (value) {
            BarOrientation.vertical => 'Vertical',
            BarOrientation.horizontal => 'Horizontal',
          },
          onChanged: (value) => setState(() => _orientation = value),
        ),
        if (_layoutMode == BarLayoutMode.overlaid ||
            _layoutMode == BarLayoutMode.stacked ||
            _layoutMode == BarLayoutMode.normalizedStacked)
          IntSliderOption(
            label: _layoutMode == BarLayoutMode.overlaid
                ? 'Overlay groups'
                : 'Named stacks',
            value: _stackGroupCount.clamp(1, _seriesCount),
            min: 1,
            max: _seriesCount,
            onChanged: (value) => setState(() => _stackGroupCount = value),
          ),
        if (_layoutMode == BarLayoutMode.overlaid)
          SliderOption(
            label: 'Layer inset',
            value: _overlayWidthStep,
            min: 0,
            max: 35,
            divisions: 7,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _overlayWidthStep = value),
          ),
        if (_layoutMode == BarLayoutMode.overlaid)
          SliderOption(
            label: 'Layer offset',
            value: _overlayOffsetStep,
            min: 0,
            max: 40,
            divisions: 8,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _overlayOffsetStep = value),
          ),
        SliderOption(
          label: 'Category fill',
          value: _barWidth,
          min: 0.2,
          max: 0.95,
          divisions: 15,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _barWidth = value),
        ),
        SliderOption(
          label: 'Bar gap',
          value: _barGap,
          min: 0,
          max: 16,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _barGap = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Shape',
      icon: Icons.rounded_corner,
      children: [
        SliderOption(
          label: 'Corner radius',
          value: _cornerRadius,
          min: 0,
          max: 32,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        EnumOption<BarCornerRadiusPolicy>(
          label: 'Rounded corners',
          value: _cornerPolicy,
          values: BarCornerRadiusPolicy.values,
          labelBuilder: (value) => switch (value) {
            BarCornerRadiusPolicy.all => 'All corners',
            BarCornerRadiusPolicy.valueEnd => 'Value end only',
          },
          onChanged: (value) => setState(() => _cornerPolicy = value),
        ),
        if (_layoutMode != BarLayoutMode.waterfall)
          BoolOption(
            label: 'Capacity tracks',
            value: _showTracks,
            onChanged: (value) => setState(() => _showTracks = value),
            subtitle: 'Show the available range behind each bar',
          ),
        if (_layoutMode == BarLayoutMode.waterfall)
          BoolOption(
            label: 'Connectors',
            value: _showConnectors,
            onChanged: (value) => setState(() => _showConnectors = value),
            subtitle: 'Link each step at its cumulative value',
          ),
        BoolOption(
          label: 'Border',
          value: _showBorder,
          onChanged: (value) => setState(() => _showBorder = value),
        ),
        if (_layoutMode != BarLayoutMode.waterfall)
          BoolOption(
            label: 'Gradient',
            value: _showGradient,
            onChanged: (value) => setState(() => _showGradient = value),
          ),
      ],
    ),
    OptionSection(
      title: 'Labels',
      icon: Icons.label_outline,
      children: [
        BoolOption(
          label: 'Value labels',
          value: _showLabels,
          onChanged: (value) => setState(() => _showLabels = value),
        ),
        if (_showLabels)
          EnumOption<BarLabelPosition>(
            label: 'Label position',
            value: _labelPosition,
            values: BarLabelPosition.values,
            labelBuilder: (value) => switch (value) {
              BarLabelPosition.auto => 'Auto',
              BarLabelPosition.insideEnd => 'Inside end',
              BarLabelPosition.insideCenter => 'Inside center',
              BarLabelPosition.outsideEnd => 'Outside end',
              BarLabelPosition.rangeEnds => 'Range ends',
            },
            onChanged: (value) => setState(() => _labelPosition = value),
          ),
        if (_showLabels && _labelPosition != BarLabelPosition.insideCenter)
          SliderOption(
            label: 'Edge offset',
            value: _labelEdgeOffset,
            min: 0,
            max: 20,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _labelEdgeOffset = value),
          ),
      ],
    ),
    if (_preset == _BarLabPreset.states)
      OptionSection(
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          SliderOption(
            label: 'Inactive opacity',
            value: _dimmedOpacity,
            min: 0.15,
            max: 0.8,
            divisions: 13,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _dimmedOpacity = value),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.motion)
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
          BoolOption(
            label: 'Animate bars',
            value: _animateBars,
            subtitle: 'Reduced-motion settings still take priority',
            onChanged: (value) => setState(() => _animateBars = value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('bar-lab-replay-motion'),
              onPressed: _animateBars
                  ? () => setState(() => _motionRevision++)
                  : null,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Replay values'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ),
        ],
      ),
  ];

  List<ChartSeries> _buildSeries() {
    final values = switch (_preset) {
      _BarLabPreset.capacity => const <double>[42, 61, 88, 35, 70, 94, 55],
      _BarLabPreset.rods => const <double>[34, 57, 46, 69, 81, 96, 62],
      _BarLabPreset.gradient => const <double>[28, 49, 64, 91, 73, 84, 58],
      _BarLabPreset.signed => const <double>[38, -24, 52, -38, 71, 26, -18],
      _BarLabPreset.overlay => const <double>[42, 61, 88, 35, 70, 94, 55],
      _BarLabPreset.offset => const <double>[38, 39, 27, 17, 10],
      _BarLabPreset.range => const <double>[25, 29, 27, 31, 28, 24, 26],
      _BarLabPreset.waterfall => const <double>[82, 28, 16, -18, -24, 7, 0],
      _BarLabPreset.horizontal => const <double>[96, 84, 73, 61, 49, 36],
      _BarLabPreset.axes => const <double>[96, 84, 73, 61, 49, 36],
      _BarLabPreset.motion =>
        _motionRevision.isEven
            ? const <double>[54, 72, 61, 88, 69, 94, 76]
            : const <double>[82, 48, 91, 63, 86, 57, 96],
      _BarLabPreset.states => const <double>[54, 72, 61, 88, 69, 94, 76],
      _BarLabPreset.stacked => const <double>[18, 24, 31, 22, 28, 35, 26],
      _BarLabPreset.normalized => const <double>[18, 24, 31, 22, 28, 35, 26],
    };
    final comparison = switch (_preset) {
      _BarLabPreset.capacity => const <double>[31, 69, 81, 52, 64, 86, 72],
      _BarLabPreset.rods => const <double>[46, 39, 71, 53, 88, 72, 90],
      _BarLabPreset.gradient => const <double>[41, 58, 51, 76, 89, 65, 78],
      _BarLabPreset.signed => const <double>[21, -39, 34, -14, 48, -28, 32],
      _BarLabPreset.overlay => const <double>[31, 69, 81, 52, 64, 86, 72],
      _BarLabPreset.offset => const <double>[40, 40, 20, 18, 16],
      _BarLabPreset.range => const <double>[23, 27, 30, 29, 26, 25, 28],
      _BarLabPreset.waterfall => const <double>[76, 22, 12, -15, -20, 5, 0],
      _BarLabPreset.horizontal => const <double>[88, 79, 68, 57, 44, 31],
      _BarLabPreset.axes => const <double>[420, 385, 352, 316, 274, 230],
      _BarLabPreset.motion =>
        _motionRevision.isEven
            ? const <double>[42, 64, 79, 58, 83, 71, 91]
            : const <double>[68, 84, 55, 92, 61, 88, 73],
      _BarLabPreset.states => const <double>[42, 64, 79, 58, 83, 71, 91],
      _BarLabPreset.stacked => const <double>[14, 19, 26, 18, 24, 29, 21],
      _BarLabPreset.normalized => const <double>[14, 19, 26, 18, 24, 29, 21],
    };

    return [
      for (var index = 0; index < _seriesCount; index++)
        _series(
          id: 'series-${index + 1}',
          name: switch ((_preset, index)) {
            (_BarLabPreset.offset, 0) => 'Summer 2020',
            (_BarLabPreset.offset, 1) => 'Current result',
            (_BarLabPreset.range, 0) => 'Observed',
            (_BarLabPreset.range, 1) => 'Forecast',
            (_BarLabPreset.waterfall, 0) => 'Current plan',
            (_BarLabPreset.waterfall, 1) => 'Previous plan',
            (_BarLabPreset.horizontal, 0) => 'Current',
            (_BarLabPreset.horizontal, 1) => 'Target',
            (_BarLabPreset.axes, _) => _axisMetric(index).name,
            (_BarLabPreset.motion, 0) => 'Actual',
            (_BarLabPreset.motion, 1) => 'Forecast',
            (_BarLabPreset.states, 0) => 'Actual',
            (_BarLabPreset.states, 1) => 'Plan',
            (_, 0) => 'Current',
            (_, 1) => 'Previous',
            _ => 'Series ${index + 1}',
          },
          values: _valuesForSeries(index, values, comparison),
          color: _preset == _BarLabPreset.offset && index == 0
              ? const Color(0xFFB8BBC2)
              : _seriesColors[index],
          gradientColors: [
            Color.lerp(_seriesColors[index], Colors.white, 0.38)!,
            _seriesColors[index],
          ],
          trackColor: Color.lerp(_seriesColors[index], Colors.white, 0.84)!,
        ),
    ];
  }

  List<double> _valuesForSeries(
    int seriesIndex,
    List<double> primary,
    List<double> comparison,
  ) {
    if (seriesIndex == 0) return primary;
    if (seriesIndex == 1) return comparison;

    return List.generate(_categories.length, (categoryIndex) {
      final seed = seriesIndex * 19 + categoryIndex * 13;
      if (_preset == _BarLabPreset.signed) {
        final magnitude = 14 + seed % 45;
        return (seriesIndex + categoryIndex) % 3 == 0
            ? -magnitude.toDouble()
            : magnitude.toDouble();
      }
      if (_preset == _BarLabPreset.stacked ||
          _preset == _BarLabPreset.normalized) {
        return (12 + seed % 32).toDouble();
      }
      if (_preset == _BarLabPreset.range) {
        return (22 + seed % 11).toDouble();
      }
      if (_preset == _BarLabPreset.waterfall) {
        if (categoryIndex == _categories.length - 1) return 0;
        if (categoryIndex == 0) return (70 + seed % 20).toDouble();
        final magnitude = (6 + seed % 24).toDouble();
        return categoryIndex == 3 || categoryIndex == 4
            ? -magnitude
            : magnitude;
      }
      if (_preset == _BarLabPreset.horizontal) {
        return (30 + seed % 70).toDouble();
      }
      if (_preset == _BarLabPreset.axes) {
        return switch (seriesIndex % 4) {
          0 => (36 + seed % 64).toDouble(),
          1 => (180 + seed * 7 % 270).toDouble(),
          2 => (58 + seed % 34).toDouble(),
          _ => (18 + seed % 24).toDouble(),
        };
      }
      return (24 + seed % 73).toDouble();
    }, growable: false);
  }

  ({
    String name,
    String axisLabel,
    String unit,
    YAxisPosition position,
    double max,
  })
  _axisMetric(int seriesIndex) {
    final cycle = seriesIndex ~/ 4;
    final metric = switch (seriesIndex % 4) {
      0 => (
        name: 'Revenue',
        axisLabel: 'Revenue',
        unit: r'$k',
        position: YAxisPosition.left,
        max: 110.0,
      ),
      1 => (
        name: 'Orders',
        axisLabel: 'Orders',
        unit: 'orders',
        position: YAxisPosition.right,
        max: 500.0,
      ),
      2 => (
        name: 'Conversion',
        axisLabel: 'Conversion',
        unit: '%',
        position: YAxisPosition.right,
        max: 100.0,
      ),
      _ => (
        name: 'Margin',
        axisLabel: 'Margin',
        unit: '%',
        position: YAxisPosition.left,
        max: 50.0,
      ),
    };
    if (cycle == 0) return metric;
    return (
      name: '${metric.name} ${cycle + 1}',
      axisLabel: '${metric.axisLabel} ${cycle + 1}',
      unit: metric.unit,
      position: metric.position,
      max: metric.max,
    );
  }

  BarChartSeries _series({
    required String id,
    required String name,
    required List<double> values,
    required Color color,
    required List<Color> gradientColors,
    required Color trackColor,
  }) {
    final seriesIndex = int.parse(id.split('-').last) - 1;
    final groupCount = _effectiveGroupCount;
    final groupIndex = seriesIndex % groupCount;
    final overlayLayer = seriesIndex ~/ groupCount;
    final overlayLayerCount =
        ((_seriesCount - 1 - groupIndex) ~/ groupCount) + 1;
    final overlayWidthFactor = (1 - overlayLayer * _overlayWidthStep / 100)
        .clamp(0.2, 1.0);
    final overlayOffsetFactor =
        (overlayLayer - (overlayLayerCount - 1) / 2) * _overlayOffsetStep / 100;
    final isFrontOverlayLayer = seriesIndex + groupCount >= _seriesCount;
    final rangeStartValues = _rangeStartsForSeries(seriesIndex, values);
    final axisMetric = _preset == _BarLabPreset.axes
        ? _axisMetric(seriesIndex)
        : null;
    return BarChartSeries(
      id: id,
      name: name,
      points: [
        for (var index = 0; index < values.length; index++)
          ChartDataPoint(
            x: index.toDouble(),
            y: values[index],
            label: _categories[index],
            pointStyle: _preset == _BarLabPreset.offset && seriesIndex == 1
                ? PointStyle.color(_medalColors[index])
                : null,
          ),
      ],
      color: color,
      unit: _preset == _BarLabPreset.signed
          ? '%'
          : _preset == _BarLabPreset.range
          ? '°C'
          : axisMetric?.unit,
      yAxisConfig: axisMetric == null
          ? null
          : YAxisConfig(
              position: axisMetric.position,
              color: color,
              label: axisMetric.axisLabel,
              unit: axisMetric.unit,
              min: 0,
              max: axisMetric.max,
              tickCount: 5,
              showCrosshairLabel: true,
            ),
      barWidthPercent: _barWidth,
      barGap: _barGap,
      orientation: _orientation,
      overlayWidthFactor: _layoutMode == BarLayoutMode.overlaid
          ? overlayWidthFactor
          : 1,
      overlayOffsetFactor: _layoutMode == BarLayoutMode.overlaid
          ? overlayOffsetFactor
          : 0,
      rangeStartValues: rangeStartValues,
      waterfallTotalIndices: _preset == _BarLabPreset.waterfall
          ? {_categories.length - 1}
          : const {},
      waterfallStyle: BarWaterfallStyle(
        increaseColor: const Color(0xFF168AAD),
        decreaseColor: const Color(0xFFE15B64),
        totalColor: const Color(0xFF5149C6),
        connector: BarWaterfallConnectorStyle(
          show: _showConnectors,
          color: const Color(0xFF9CA3AF),
          width: 1.25,
        ),
      ),
      minBarLength: 4,
      barStyle: BarChartStyle(
        animationMode: _animateBars
            ? BarAnimationMode.grow
            : BarAnimationMode.none,
        cornerRadius: _cornerRadius,
        cornerRadiusPolicy: _cornerPolicy,
        gradient: _showGradient ? BarGradient(colors: gradientColors) : null,
        border: _showBorder
            ? BarBorderStyle(color: color.withValues(alpha: 0.9), width: 1.5)
            : null,
        interaction: BarInteractionStyle(dimmedOpacity: _dimmedOpacity),
      ),
      trackStyle: _showTracks
          ? BarTrackStyle(
              color: trackColor,
              value: _preset == _BarLabPreset.signed
                  ? null
                  : _preset == _BarLabPreset.range
                  ? 34
                  : 100,
              cornerRadius: _cornerRadius,
            )
          : null,
      labelStyle: BarLabelStyle(
        show:
            _showLabels &&
            (_layoutMode != BarLayoutMode.overlaid || isFrontOverlayLayer),
        position: _labelPosition,
        valueMode: _layoutMode == BarLayoutMode.normalizedStacked
            ? BarLabelValueMode.percentage
            : _preset == _BarLabPreset.range
            ? BarLabelValueMode.range
            : _preset == _BarLabPreset.waterfall
            ? BarLabelValueMode.waterfall
            : BarLabelValueMode.value,
        showUnit:
            _preset == _BarLabPreset.signed ||
            _preset == _BarLabPreset.range ||
            _preset == _BarLabPreset.axes,
        padding: _labelEdgeOffset,
      ),
      layoutMode: _layoutMode,
      groupId:
          _layoutMode == BarLayoutMode.overlaid ||
              _layoutMode == BarLayoutMode.stacked ||
              _layoutMode == BarLayoutMode.normalizedStacked
          ? 'group-${seriesIndex % groupCount}'
          : null,
    );
  }

  List<double?> _rangeStartsForSeries(int seriesIndex, List<double> values) {
    if (_preset != _BarLabPreset.range) return const [];
    if (seriesIndex == 0) return const [14, 17, 15, 19, 16, 13, 14];
    if (seriesIndex == 1) return const [12, 16, 18, 17, 15, 14, 17];
    return [
      for (var index = 0; index < values.length; index++)
        values[index] - 8 - ((seriesIndex + index) % 4),
    ];
  }

  int get _effectiveGroupCount => _stackGroupCount.clamp(1, _seriesCount);

  bool _supportsLayout(_BarLabPreset preset, BarLayoutMode mode) {
    if (preset == _BarLabPreset.waterfall) {
      return mode == BarLayoutMode.waterfall;
    }
    if (mode == BarLayoutMode.waterfall) return false;
    return preset != _BarLabPreset.range ||
        mode == BarLayoutMode.grouped ||
        mode == BarLayoutMode.overlaid;
  }

  List<String> get _categories => switch (_preset) {
    _BarLabPreset.offset => _medalCategories,
    _BarLabPreset.waterfall => _waterfallCategories,
    _BarLabPreset.horizontal => _channelCategories,
    _BarLabPreset.axes => _channelCategories,
    _ => _dayCategories,
  };

  void _applyPreset(_BarLabPreset preset) {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _preset = preset;
      _setPresetValues(preset);
    });
  }

  void _setPresetValues(_BarLabPreset preset) {
    _showBorder = false;
    _showConnectors = true;
    _dimmedOpacity = 0.42;
    _overlayWidthStep = 22;
    _overlayOffsetStep = 0;
    _labelPosition = BarLabelPosition.auto;
    _labelEdgeOffset = 8;
    _orientation = BarOrientation.vertical;
    _motionRevision = 0;
    _motionDurationMs = 650;
    _animateBars = true;
    switch (preset) {
      case _BarLabPreset.capacity:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.72;
        _barGap = 4;
        _cornerRadius = 6;
        _showTracks = true;
        _showGradient = false;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.rods:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.34;
        _barGap = 10;
        _cornerRadius = 32;
        _showTracks = false;
        _showGradient = false;
        _showLabels = false;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.gradient:
        _seriesCount = 4;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.68;
        _barGap = 4;
        _cornerRadius = 10;
        _showTracks = false;
        _showGradient = true;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.signed:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.68;
        _barGap = 4;
        _cornerRadius = 7;
        _showTracks = false;
        _showGradient = false;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.overlay:
        _seriesCount = 4;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.overlaid;
        _barWidth = 0.72;
        _barGap = 4;
        _overlayWidthStep = 22;
        _cornerRadius = 6;
        _showTracks = true;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.auto;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.offset:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.overlaid;
        _barWidth = 0.68;
        _barGap = 4;
        _overlayWidthStep = 0;
        _overlayOffsetStep = 30;
        _cornerRadius = 2;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.range:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.64;
        _barGap = 8;
        _cornerRadius = 8;
        _showTracks = false;
        _showGradient = true;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.rangeEnds;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.waterfall:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.waterfall;
        _barWidth = 0.62;
        _barGap = 4;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _showConnectors = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.horizontal:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.72;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.axes:
        _seriesCount = 4;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.76;
        _barGap = 4;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.motion:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.7;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.states:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.7;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _dimmedOpacity = 0.32;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.stacked:
        _seriesCount = 6;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.stacked;
        _barWidth = 0.78;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.normalized:
        _seriesCount = 6;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.normalizedStacked;
        _barWidth = 0.78;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
    }
  }

  void _resetPreset() => _applyPreset(_preset);

  String _categoryLabel(double value) {
    final index = value.round();
    if (index < 0 || index >= _categories.length) return '';
    return _categories[index];
  }

  String _presetTitle() => switch (_preset) {
    _BarLabPreset.capacity => 'Progress against capacity',
    _BarLabPreset.rods => 'Compact rounded rods',
    _BarLabPreset.gradient => 'Value-axis gradients',
    _BarLabPreset.signed => 'Positive and negative values',
    _BarLabPreset.overlay => 'Layered comparisons',
    _BarLabPreset.offset => 'Offset comparisons',
    _BarLabPreset.range => 'Floating temperature ranges',
    _BarLabPreset.waterfall => 'Cash-flow bridge',
    _BarLabPreset.horizontal => 'Revenue by channel',
    _BarLabPreset.axes => 'Independent channel metrics',
    _BarLabPreset.motion => 'Animated value updates',
    _BarLabPreset.states => 'Interactive bar states',
    _BarLabPreset.stacked => 'Named stacked totals',
    _BarLabPreset.normalized => '100% stacked composition',
  };

  String _presetDescription() => switch (_preset) {
    _BarLabPreset.capacity =>
      'Tracks reveal remaining capacity without adding another data series.',
    _BarLabPreset.rods =>
      'Narrow bars and full rounding create a compact dashboard treatment.',
    _BarLabPreset.gradient =>
      'Gradients follow each bar from its baseline to its value end.',
    _BarLabPreset.signed =>
      'Negative values use the same geometry and round away from the baseline.',
    _BarLabPreset.overlay =>
      'Wide reference bars remain visible behind narrower comparison layers.',
    _BarLabPreset.offset =>
      'Equal-width results shift left and right for a compact reference comparison.',
    _BarLabPreset.range =>
      'Each bar spans an explicit start and end instead of growing from zero.',
    _BarLabPreset.waterfall =>
      'Sequential increases and decreases bridge the opening value to a resolved total.',
    _BarLabPreset.horizontal =>
      'Horizontal ranking gives category names room while values remain easy to compare.',
    _BarLabPreset.axes =>
      'Independent value axes stack above and below one shared category plot.',
    _BarLabPreset.motion =>
      'Replay value changes through the same geometry used for labels and interaction.',
    _BarLabPreset.states =>
      'Hover, press, click, or use the arrow keys and Enter to inspect every state.',
    _BarLabPreset.stacked =>
      'Two named stacks compare totals while preserving every contribution.',
    _BarLabPreset.normalized =>
      'Each named stack resolves to 100% while tooltips retain raw values.',
  };

  String _chartSummary() {
    final features = <String>[
      '$_seriesCount series',
      _orientation.name,
      _layoutMode == BarLayoutMode.grouped
          ? 'grouped'
          : _layoutMode == BarLayoutMode.overlaid
          ? 'overlaid · $_effectiveGroupCount ${_effectiveGroupCount == 1 ? 'group' : 'groups'}'
          : _layoutMode == BarLayoutMode.waterfall
          ? 'waterfall'
          : '${_layoutLabel(_layoutMode).toLowerCase()} · $_effectiveGroupCount ${_effectiveGroupCount == 1 ? 'stack' : 'stacks'}',
      '${(_barWidth * 100).round()}% category fill',
      if (_showTracks) 'capacity tracks',
      if (_showGradient) 'gradient fill',
      if (_preset == _BarLabPreset.range) 'floating ranges',
      if (_preset == _BarLabPreset.waterfall) 'cumulative bridge',
      if (_preset == _BarLabPreset.waterfall && _showConnectors) 'connectors',
      if (_preset == _BarLabPreset.axes) 'independent value axes',
      if (_preset == _BarLabPreset.motion && _animateBars)
        '${_motionDurationMs.round()}ms updates',
      if (_preset == _BarLabPreset.states)
        '${_chartController.selectedPointRefs.length} selected',
      if (_showLabels)
        _layoutMode == BarLayoutMode.overlaid
            ? 'front-layer ${_labelPosition.name} labels'
            : '${_labelPosition.name} labels',
    ];
    return features.join(' · ');
  }

  String _layoutLabel(BarLayoutMode mode) => switch (mode) {
    BarLayoutMode.grouped => 'Grouped',
    BarLayoutMode.overlaid => 'Overlaid',
    BarLayoutMode.stacked => 'Stacked',
    BarLayoutMode.normalizedStacked => '100% stacked',
    BarLayoutMode.waterfall => 'Waterfall',
  };
}

class _BarLabLegendItem extends StatelessWidget {
  const _BarLabLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
