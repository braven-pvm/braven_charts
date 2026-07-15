// Copyright 2025 Braven Charts - Baseline Fill Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _BaselinePattern { target, zeroCentered, deviation, stepped }

/// A focused workbench for baseline-relative area fills.
class BaselineAreaDemoPage extends StatefulWidget {
  const BaselineAreaDemoPage({super.key});

  @override
  State<BaselineAreaDemoPage> createState() => _BaselineAreaDemoPageState();
}

class _BaselineAreaDemoPageState extends State<BaselineAreaDemoPage> {
  static const _blue = Color(0xFF3478D4);
  static const _green = Color(0xFF10A37F);
  static const _red = Color(0xFFEF445C);
  static const _orange = Color(0xFFF59E0B);
  static const _purple = Color(0xFF8B5CF6);
  static const _cyan = Color(0xFF0891B2);

  final ChartOptionsController _optionsController = ChartOptionsController();

  _BaselinePattern _selectedPattern = _BaselinePattern.target;
  double _baseline = 120;
  LineInterpolation _interpolation = LineInterpolation.monotone;
  Color _strokeColor = _blue;
  Color _aboveColor = _green;
  Color _belowColor = _red;
  double _fillOpacity = 0.32;
  double _strokeWidth = 2.5;
  bool _showBaseline = true;
  bool _showMarkers = false;

  static const _targetData = [
    ChartDataPoint(x: 0, y: 105),
    ChartDataPoint(x: 1, y: 138),
    ChartDataPoint(x: 2, y: 155),
    ChartDataPoint(x: 3, y: 148),
    ChartDataPoint(x: 4, y: 112),
    ChartDataPoint(x: 5, y: 88),
    ChartDataPoint(x: 6, y: 75),
    ChartDataPoint(x: 7, y: 118),
    ChartDataPoint(x: 8, y: 145),
    ChartDataPoint(x: 9, y: 162),
    ChartDataPoint(x: 10, y: 130),
    ChartDataPoint(x: 11, y: 95),
    ChartDataPoint(x: 12, y: 82),
    ChartDataPoint(x: 13, y: 108),
    ChartDataPoint(x: 14, y: 133),
    ChartDataPoint(x: 15, y: 158),
    ChartDataPoint(x: 16, y: 142),
    ChartDataPoint(x: 17, y: 117),
    ChartDataPoint(x: 18, y: 91),
    ChartDataPoint(x: 19, y: 78),
    ChartDataPoint(x: 20, y: 102),
    ChartDataPoint(x: 21, y: 125),
    ChartDataPoint(x: 22, y: 147),
    ChartDataPoint(x: 23, y: 165),
    ChartDataPoint(x: 24, y: 135),
  ];

  static const _deltaData = [
    ChartDataPoint(x: 0, y: -4),
    ChartDataPoint(x: 2, y: 2),
    ChartDataPoint(x: 4, y: 7),
    ChartDataPoint(x: 6, y: 3),
    ChartDataPoint(x: 8, y: -2),
    ChartDataPoint(x: 10, y: -7),
    ChartDataPoint(x: 12, y: -1),
    ChartDataPoint(x: 14, y: 5),
    ChartDataPoint(x: 16, y: 10),
    ChartDataPoint(x: 18, y: 4),
    ChartDataPoint(x: 20, y: -3),
    ChartDataPoint(x: 22, y: -8),
    ChartDataPoint(x: 24, y: -2),
  ];

  static const _steppedData = [
    ChartDataPoint(x: 0, y: 90),
    ChartDataPoint(x: 3, y: 145),
    ChartDataPoint(x: 6, y: 105),
    ChartDataPoint(x: 9, y: 160),
    ChartDataPoint(x: 12, y: 80),
    ChartDataPoint(x: 15, y: 135),
    ChartDataPoint(x: 18, y: 95),
    ChartDataPoint(x: 21, y: 150),
    ChartDataPoint(x: 24, y: 110),
  ];

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Baseline Fill',
      subtitle:
          'Split an area at zero, a target, or any Y reference with independently styled regions',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          'Choose a baseline pattern',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );
        final guide = _BaselineGuide(
          key: const ValueKey('baseline-guide'),
          pattern: _selectedPattern,
        );

        if (constraints.maxHeight < 420) {
          return ListView(
            children: [
              heading,
              const SizedBox(height: 8),
              SizedBox(height: 172, child: _buildPatternRibbon()),
              const SizedBox(height: 16),
              guide,
              const SizedBox(height: 16),
              SizedBox(height: 430, child: _buildMainStage()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 8),
            SizedBox(height: 172, child: _buildPatternRibbon()),
            const SizedBox(height: 16),
            guide,
            const SizedBox(height: 16),
            Expanded(child: _buildMainStage()),
          ],
        );
      },
    );
  }

  Widget _buildPatternRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 920
            ? (constraints.maxWidth - gap * 3) / 4
            : 200.0;
        return SingleChildScrollView(
          key: const ValueKey('baseline-pattern-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _BaselinePattern.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _BaselinePatternCard(
                    key: ValueKey(
                      'baseline-pattern-${_BaselinePattern.values[index].name}',
                    ),
                    pattern: _BaselinePattern.values[index],
                    selected:
                        _selectedPattern == _BaselinePattern.values[index],
                    onTap: () => _selectPattern(_BaselinePattern.values[index]),
                    chart: _buildPatternPreview(_BaselinePattern.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(_BaselinePattern pattern) {
    final defaults = _defaultsFor(pattern);
    return BravenChartPlus(
      key: ValueKey('baseline-preview-${pattern.name}'),
      series: [_seriesFor(pattern, defaults: defaults, preview: true)],
      annotations: [
        _annotationFor(defaults.baseline, defaults.stroke, compact: true),
      ],
      xAxisConfig: const XAxisConfig(
        showTickLabels: false,
        showTicks: false,
        showAxisLine: true,
        minHeight: 8,
        maxHeight: 8,
        min: -1,
        max: 25,
        renderMin: 0,
        renderMax: 24,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        showTickLabels: false,
        showTicks: false,
        maxWidth: 14,
        min: pattern == _BaselinePattern.zeroCentered ? -14 : 60,
        max: pattern == _BaselinePattern.zeroCentered ? 14 : 185,
      ),
      grid: const GridConfig(horizontal: false, vertical: false),
      showLegend: false,
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
      ),
    );
  }

  Widget _buildMainStage() {
    return ChartCard(
      key: const ValueKey('baseline-main-stage'),
      title: _patternLabel(_selectedPattern),
      subtitle: _stageSubtitle(_selectedPattern),
      child: ListenableBuilder(
        listenable: _optionsController,
        builder: (context, _) => BravenChartPlus(
          key: ValueKey('baseline-main-chart-${_selectedPattern.name}'),
          series: [_seriesFor(_selectedPattern)],
          annotations: _showBaseline
              ? [_annotationFor(_baseline, _strokeColor)]
              : const [],
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
            autoHide: false,
          ),
          xAxisConfig: XAxisConfig(
            label: 'Time',
            unit: 'min',
            min: -1,
            max: 25,
            renderMin: 0,
            renderMax: 24,
            showAxisLine: _optionsController.showAxisLines,
          ),
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: _selectedPattern == _BaselinePattern.zeroCentered
                ? 'Change'
                : 'Power',
            unit: _selectedPattern == _BaselinePattern.zeroCentered ? '%' : 'W',
            min: _selectedPattern == _BaselinePattern.zeroCentered ? -14 : 60,
            max: _selectedPattern == _BaselinePattern.zeroCentered ? 14 : 185,
            showAxisLine: _optionsController.showAxisLines,
          ),
          grid: GridConfig(
            horizontal: _optionsController.showGrid,
            vertical: _optionsController.showGrid,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
            crosshair: CrosshairConfig.tracking(interpolate: true),
            tooltip: const TooltipConfig(enabled: true),
          ),
        ),
      ),
    );
  }

  AreaChartSeries _seriesFor(
    _BaselinePattern pattern, {
    _BaselineDefaults? defaults,
    bool preview = false,
  }) {
    final resolved = defaults ?? _currentDefaults;
    return AreaChartSeries(
      id: 'baseline-${pattern.name}',
      name: _patternSeriesName(pattern),
      points: pattern == _BaselinePattern.zeroCentered
          ? _deltaData
          : pattern == _BaselinePattern.stepped
          ? _steppedData
          : _targetData,
      color: resolved.stroke,
      interpolation: resolved.interpolation,
      strokeWidth: preview ? 1.6 : _strokeWidth,
      fillOpacity: preview ? 0.28 : _fillOpacity,
      showDataPointMarkers:
          !preview && (_showMarkers || _optionsController.showDataMarkers),
      dataPointMarkerRadius: 3.5,
      baselineValue: resolved.baseline,
      aboveBaselineFillColor: resolved.above.withValues(
        alpha: preview ? 0.28 : _fillOpacity,
      ),
      belowBaselineFillColor: resolved.below.withValues(
        alpha: preview ? 0.28 : _fillOpacity,
      ),
    );
  }

  ThresholdAnnotation _annotationFor(
    double value,
    Color color, {
    bool compact = false,
  }) {
    return ThresholdAnnotation(
      id: compact ? 'preview-baseline' : 'active-baseline',
      axis: AnnotationAxis.y,
      value: value,
      label: compact ? null : _baselineLabel,
      lineColor: color.withValues(alpha: compact ? 0.5 : 0.8),
      lineWidth: compact ? 1 : 1.5,
      dashPattern: const [6, 4],
      labelPosition: AnnotationLabelPosition.topRight,
    );
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Baseline',
        icon: Icons.horizontal_rule,
        children: [
          SliderOption(
            label: 'Baseline Value',
            value: _baseline,
            min: _selectedPattern == _BaselinePattern.zeroCentered ? -8 : 80,
            max: _selectedPattern == _BaselinePattern.zeroCentered ? 8 : 160,
            divisions: _selectedPattern == _BaselinePattern.zeroCentered
                ? 16
                : 16,
            suffix: _selectedPattern == _BaselinePattern.zeroCentered
                ? '%'
                : 'W',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _baseline = value),
          ),
          BoolOption(
            label: 'Show Reference Line',
            subtitle: 'A threshold annotation makes the split explicit',
            value: _showBaseline,
            onChanged: (value) => setState(() => _showBaseline = value),
          ),
          EnumOption<LineInterpolation>(
            label: 'Interpolation',
            value: _interpolation,
            values: LineInterpolation.values,
            labelBuilder: (value) => value.name,
            onChanged: (value) => setState(() => _interpolation = value),
          ),
        ],
      ),
      OptionSection(
        title: 'Region Styling',
        icon: Icons.format_color_fill_outlined,
        children: [
          ColorOption(
            label: 'Above Baseline',
            value: _aboveColor,
            colors: const [_green, _red, _orange, _purple, _cyan, _blue],
            onChanged: (value) => setState(() => _aboveColor = value),
          ),
          ColorOption(
            label: 'Below Baseline',
            value: _belowColor,
            colors: const [_red, _green, _orange, _purple, _cyan, _blue],
            onChanged: (value) => setState(() => _belowColor = value),
          ),
          ColorOption(
            label: 'Series Stroke',
            value: _strokeColor,
            colors: const [_blue, _purple, _cyan, _orange, _green, _red],
            onChanged: (value) => setState(() => _strokeColor = value),
          ),
          SliderOption(
            label: 'Fill Opacity',
            value: _fillOpacity,
            min: 0.1,
            max: 0.7,
            divisions: 12,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _fillOpacity = value),
          ),
          SliderOption(
            label: 'Stroke Width',
            value: _strokeWidth,
            min: 1,
            max: 6,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _strokeWidth = value),
          ),
          BoolOption(
            label: 'Show Data Markers',
            value: _showMarkers,
            onChanged: (value) => setState(() => _showMarkers = value),
          ),
        ],
      ),
      StandardChartOptions(
        controller: _optionsController,
        showMarkerOption: false,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Reset',
        icon: Icons.restart_alt,
        initiallyExpanded: false,
        children: [
          ActionButton(
            label: 'Reset Pattern',
            icon: Icons.restart_alt,
            onPressed: () => _selectPattern(_selectedPattern, force: true),
          ),
        ],
      ),
    ];
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(label: 'Pattern', value: _patternLabel(_selectedPattern)),
        StatusItem(label: 'Baseline', value: _baselineLabel),
        StatusItem(label: 'Interpolation', value: _interpolation.name),
        const StatusItem(label: 'API', value: 'AreaChartSeries'),
      ],
    );
  }

  void _selectPattern(_BaselinePattern pattern, {bool force = false}) {
    if (_selectedPattern == pattern && !force) return;
    final defaults = _defaultsFor(pattern);
    setState(() {
      _selectedPattern = pattern;
      _baseline = defaults.baseline;
      _interpolation = defaults.interpolation;
      _strokeColor = defaults.stroke;
      _aboveColor = defaults.above;
      _belowColor = defaults.below;
      _fillOpacity = defaults.opacity;
      _strokeWidth = 2.5;
      _showBaseline = true;
      _showMarkers = false;
    });
  }

  _BaselineDefaults get _currentDefaults => _BaselineDefaults(
    baseline: _baseline,
    interpolation: _interpolation,
    stroke: _strokeColor,
    above: _aboveColor,
    below: _belowColor,
    opacity: _fillOpacity,
  );

  String get _baselineLabel => _selectedPattern == _BaselinePattern.zeroCentered
      ? '${_baseline.toStringAsFixed(0)}%'
      : '${_baseline.toStringAsFixed(0)} W';

  static _BaselineDefaults _defaultsFor(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target => const _BaselineDefaults(
        baseline: 120,
        interpolation: LineInterpolation.monotone,
        stroke: _blue,
        above: _green,
        below: _red,
        opacity: 0.32,
      ),
      _BaselinePattern.zeroCentered => const _BaselineDefaults(
        baseline: 0,
        interpolation: LineInterpolation.monotone,
        stroke: _purple,
        above: _red,
        below: _green,
        opacity: 0.28,
      ),
      _BaselinePattern.deviation => const _BaselineDefaults(
        baseline: 120,
        interpolation: LineInterpolation.linear,
        stroke: _orange,
        above: _orange,
        below: _orange,
        opacity: 0.26,
      ),
      _BaselinePattern.stepped => const _BaselineDefaults(
        baseline: 120,
        interpolation: LineInterpolation.stepped,
        stroke: _purple,
        above: _cyan,
        below: _red,
        opacity: 0.32,
      ),
    };
  }

  static String _patternLabel(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target => 'Above / below target',
      _BaselinePattern.zeroCentered => 'Positive / negative',
      _BaselinePattern.deviation => 'Magnitude of deviation',
      _BaselinePattern.stepped => 'Stepped regimes',
    };
  }

  static String _patternDescription(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target => 'Independent semantic regions',
      _BaselinePattern.zeroCentered => 'Zero-centred gain and loss',
      _BaselinePattern.deviation => 'One colour on both sides',
      _BaselinePattern.stepped => 'Splits align to step edges',
    };
  }

  static String _stageSubtitle(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target =>
        'The fill changes colour exactly where the series crosses the target',
      _BaselinePattern.zeroCentered =>
        'Use a zero baseline for deltas, residuals, gains, and losses',
      _BaselinePattern.deviation =>
        'Matching region colours show distance from target without good/bad semantics',
      _BaselinePattern.stepped =>
        'Baseline clipping follows the selected interpolation, including vertical steps',
    };
  }

  static String _patternSeriesName(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target => 'Power vs target',
      _BaselinePattern.zeroCentered => 'Change from baseline',
      _BaselinePattern.deviation => 'Target deviation',
      _BaselinePattern.stepped => 'Operating regime',
    };
  }
}

class _BaselineDefaults {
  const _BaselineDefaults({
    required this.baseline,
    required this.interpolation,
    required this.stroke,
    required this.above,
    required this.below,
    required this.opacity,
  });

  final double baseline;
  final LineInterpolation interpolation;
  final Color stroke;
  final Color above;
  final Color below;
  final double opacity;
}

class _BaselinePatternCard extends StatelessWidget {
  const _BaselinePatternCard({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _BaselinePattern pattern;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _BaselineAreaDemoPageState._patternLabel(pattern),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      key: ValueKey('selected-baseline-${pattern.name}'),
                      size: 16,
                      color: colors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _BaselineAreaDemoPageState._patternDescription(pattern),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(child: IgnorePointer(child: chart)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BaselineGuide extends StatelessWidget {
  const _BaselineGuide({super.key, required this.pattern});

  final _BaselinePattern pattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Row(
            children: [
              Icon(_icon(pattern), size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _explanation(pattern),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
          final api = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'baselineValue · aboveBaselineFillColor · belowBaselineFillColor',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(child: explanation),
                const SizedBox(width: 16),
                SizedBox(width: 470, child: api),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [explanation, const SizedBox(height: 10), api],
          );
        },
      ),
    );
  }

  static IconData _icon(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target => Icons.flag_outlined,
      _BaselinePattern.zeroCentered => Icons.exposure,
      _BaselinePattern.deviation => Icons.compare_arrows,
      _BaselinePattern.stepped => Icons.stairs_outlined,
    };
  }

  static String _explanation(_BaselinePattern pattern) {
    return switch (pattern) {
      _BaselinePattern.target =>
        'Use contrasting fills when above and below a target carry different meaning.',
      _BaselinePattern.zeroCentered =>
        'Set baselineValue to 0 for values that move between positive and negative.',
      _BaselinePattern.deviation =>
        'Use the same fill on both sides when only the size of deviation matters.',
      _BaselinePattern.stepped =>
        'The renderer detects crossings using the series interpolation, so stepped fills stay aligned.',
    };
  }
}
